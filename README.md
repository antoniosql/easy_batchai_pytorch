# Creating a serverless deep-learning platform with Azure Batch AI
Batch AI is an Azure service that allows users to easily experiment and train their deep learning and AI models in parallel at scale. The advantages of Azure Batch AI include:

- __Easy deployment and flexibility:__ Focus on your workload, not your infrastructure by leaving resource provisioning and management to Batch AI. The service will deploy virtual machines, containers, and connect your shared storage and configure SSK for login. Batch AI Training provides a flexible programming model and SDK so you can easily integrate your own pipeline and workflow. Because Batch AI handles deployment, it’s easy to iterate on your networks and hyper-parameters.

- __High performance training:__ Batch AI works with all Microsoft Azure VM families, including the latest NVIDIA GPU’s connected with InfiniBand. This gives you the ability to scale the compute resources to whatever your models and training data require. The same powerful infrastructure Microsoft uses for its AI development is now available to you, on demand.

- __Supports any framework:__ Use any AI framework or libraries. Azure Batch AI has deep support for CNTK, TensorFlow, Chainer, and more. Or bring your code in a Docker Container and we’ll handle the rest. Batch AI supports the Azure command line, Jupyter Notebooks, scripting the service using our Python library, and integrating workflows with the REST API and SDK for C#, Java and other languages. You can use the tooling you’re comfortable with.

In this tutorial we demonstrate how to create a serverless deep-learning platform whereby an ML practitioner can submit deep-learning jobs (specifically PyTorch) without having to worrying about the underlying infrastructure (GPU, inifiband, etc).

## Prerequisites

* __An Azure subscription__ - If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?WT.mc_id=A261C142F) before you begin.
* __Installed the Azure CLI 2.0 with version 0.3 or higher of the batchai module__ - see these [instructions](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
* __Azure storage account__ - Typically we would expect that a storage account and blob container already exist with the data stored (see below). If a storage account with data does not yet exist then see [How to create an Azure storage account](https://docs.microsoft.com/en-gb/azure/storage/common/storage-create-storage-account)

## Azure Batch AI Fundamentals
Under an Azure Resource Group, the Azure Batch account contains the following resources:

1. Workspaces
2. Experiments
3. Clusters
4. File Servers
5. Experiments
6. Jobs

The image below shows a recommended approach for devising the resource hierarchy. The Batch AI workspace collects related training jobs under an experiment, and organizes all related Batch AI resources (clusters, file servers, experiments, jobs). The workspace helps to separate work belonging to different groups (e.g. Dev/Test/Production). For example, you might have a dev and a test workspace. You probably need only a limited number of workspaces per subscription. 
Experiment - A collection of related jobs that can be queried and managed together. For example, use an experiment to group all jobs that are performed as part of a hyper-parameter tuning sweep. 

![](img/batchai_hierachy.png?raw=true "Batch AI Resource Hierarchy")

Whilst NFS and local storage on the compute nodes will be the optimized method for deep-learning training due to data locality, often unstructured data (images, video, sound, text) is stored in a data lake (Azure Blob storage). Typically the extra performance from NFS/local storage is not enough to compensate for the cost of data movement from the data lake to NFS/local storage.

Therefore, a very high level architecture is:

![](img/batchai_flow.png?raw=true "Batch AI architecture")

The workflow is as follows:

1. Unstructured data is ingested into Azure blob store. We recommend using the follow directory structure:
```
landing
│   README.md
│   file001.txt    
│
└───folder1
│   │   file011.txt
│   │   file012.txt
│   │
│   └───subfolder1
│       │   file111.txt
│       │   file112.txt
│       │   ...
│   
└───folder2
    │   file021.txt
    │   file022.txt
```
  

2. 
