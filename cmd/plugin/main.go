package main

import (
	"context"
	"flag"
	"os"
	"os/signal"
	"sync"
	"time"

	podnetworkclientset "github.com/aman0408/multi-network-using-dra/pkg/client/clientset/versioned"
	podnetworkfactory "github.com/aman0408/multi-network-using-dra/pkg/client/informers/externalversions"
	"github.com/aman0408/multi-network-using-dra/pkg/plugin"
	"github.com/aman0408/multi-network-using-dra/pkg/podnet"
	"golang.org/x/sys/unix"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	nodeutil "k8s.io/component-helpers/node/util"
	"k8s.io/klog/v2"
)

const (
	driverName       = "podnetwork.example.com"
	hostnameOverride = ""
)

func main() {
	// Initialize klog and parse flags
	klog.InitFlags(nil)
	flag.Parse()

	// Set up the logger
	logger := klog.NewKlogr()

	logger.Info("Starting DRA/NRI Node Plugin")

	pnShare := &podnet.PNShare{
		PodNetworkTrigger: make(chan bool),
		DranetData:        make(map[string]*podnet.DranetData, 0),
		Lock:              &sync.Mutex{},
	}

	// When running inside a pod, we use the in-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		logger.Error(err, "Failed to get in-cluster config")
		os.Exit(1)
	}

	// Create a Kubernetes clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		logger.Error(err, "Failed to create kubernetes clientset")
		os.Exit(1)
	}

	nodeName, err := nodeutil.GetHostname(hostnameOverride)
	if err != nil {
		klog.Fatalf("can not obtain the node name, use the hostname-override flag if you want to set it to a specific value: %v", err)
	}
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)

	// Enable signal handler
	signalCh := make(chan os.Signal, 2)
	defer func() {
		close(signalCh)
		cancel()
	}()
	signal.Notify(signalCh, os.Interrupt, unix.SIGINT)

	// Create a new plugin manager
	// This manager will handle the lifecycle of both the DRA driver and NRI plugin
	driver, err := plugin.Start(ctx, driverName, nodeName, pnShare, clientset)
	if err != nil {
		logger.Error(err, "Failed to create plugin manager")
		os.Exit(1)
	}
	defer driver.Stop()

	err = startPodNetworkController(ctx, config, pnShare)
	if err != nil {
		klog.Fatalf("PodNetwork ctrl failed to start: %v", err)
	}
	select {
	case <-signalCh:
		klog.Infof("Exiting: received signal")
		cancel()
	case <-ctx.Done():
	}
}

func startPodNetworkController(ctx context.Context, kubeConfig *rest.Config, pnShare *podnet.PNShare) error {
	networkClient, err := podnetworkclientset.NewForConfig(kubeConfig)
	if err != nil {
		return err
	}
	nwInfFactory := podnetworkfactory.NewSharedInformerFactory(networkClient, 0*time.Second)
	nwInformer := nwInfFactory.Multinetwork().V1alpha1().PodNetworks()

	podNetworkController := podnet.NewPodNetworkController(
		nwInformer,
		networkClient,
		nwInfFactory,
		pnShare,
	)

	go podNetworkController.Run(1, ctx.Done())
	return nil
}
