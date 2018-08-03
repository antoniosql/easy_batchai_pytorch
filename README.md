# A deep-learning job service with Azure Batch AI

An ML practitioner often starts coding a new deep-learning project locally on a laptop or workstation using their favourite frameworks (PyTorch, TensorFlow, CNTK, etc) and tools (PyCharm, VS Code/Studio, Jupyter). However, training deep-learning models is a compute intensive task that can take a long time on a CPU machine. This bottleneck often frustrates the ML practitioner from iterating quickly on the network architecture and hyper-parameters. In order to achieve reasonable training times for deep-learning networks a GPU machine - and for very deep networks - a cluster of GPU machines is required. With this in mind the ML practitioner could use an on-prem/cloud GPU VM to scale the job, however:

* the VM needs to be set-up and configured with the appropriate tools and frameworks
* a single VM does not scale to multiple users that are each submitting compute intensive tasks

The purpose of this tutorial is to demonstrate how an ML practitioner can develop deep-learning code on their local machine and easily submit the code as a job to a cloud-based (Azure Batch AI) GPU service. The benefits of such a service are:

* The ML practitioner does not have to concern themselves with the underlying infrastructure (GPU, infiniband, etc).
* The service we construct using Azure Batch AI is virtually __serverless__ i.e. once a job is submitted the underlying service spins up the compute resource that is required, runs the job, and then spins down.
* __Auto-scales__ with the number of jobs submitted.
* Supports __any framework__ - Tensorflow, PyTorch, CNTK, Chainer and more.
* Supports __distributed deep-learning__ (multi-node, multi-gpu) with Horovod.
* Supports Azure low-priority VMs, which provide an 80% discount on the compute.

## Prerequisites

* __An Azure subscription__ - If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?WT.mc_id=A261C142F) before you begin.
* __Installed the Azure CLI 2.0 with version 0.3 or higher of the batchai module__ - see these [instructions](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
* __Powershell__ (future work is to replicate with bash scripts)
* __Azure storage account__ - Typically we would expect that a storage account and blob container already exist with the data stored (see below). If a storage account with data does not yet exist then see [How to create an Azure storage account](https://docs.microsoft.com/en-gb/azure/storage/common/storage-create-storage-account)

## High-level AI architecture

A high-level holistic AI architecuture in Azure would look as follows:

![](00_doc/img/batchai_flow.png?raw=true "Batch AI architecture")

where the workflow flow is as follows:

1. The data engineer:
    * ingests the unstructured data into the data lake (Azure blob store) landing directory
    * prepares the full dataset into the correct folder structure for training on job service
    * prepares a sample of the data into the correct folder structure for training on a local machine
2. The ML practitioner:
    * downloads the sample from Azure Blob (using CLI or Azure Storage Explorer)
    * develops skeleton code in their favourite editor and debug locally
    * submits the code to the deep-learning job service (GPU) and receives back the artifacts (e.g. models(.
        * repeats until model is ready for production
3. The developer takes the deep-learning code and builds an AI pipeline in VSTS that:
    * trains the model
    * serves the model into an autoscale Kubernetes cluster (REST API endpoint) using Azure ML (see example [here](https://docs.microsoft.com/en-us/azure/machine-learning/desktop-workbench/model-management-service-deploy))
    * integrates the model into the application using the REST API endpoint

In this tutorial we focus on the setting up the Deep-Learning Job Service and how the ML practitioner interacts with it.

## Documentation and code

Often organisations have a dedicated team responsible for implementing cloud based services that are then consumed by internal customers. Therefore, we have split the documentation and code into:

* [Cloud Administrator Guide](00_doc/cloud_admin_doc.md): Setting up a deep-learning job service with Azure Batch AI
* [ML Practitioner Guide](00_doc/ml_practitioner_doc.md): Submitting deep-learning jobs

This allows us to tailor the documentation for each persona.

