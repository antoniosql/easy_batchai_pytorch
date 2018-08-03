# ML Practitioner Guide: Submitting deep-learning jobs

In this guide we demonstrate how an ML practitioner can submit jobs to the deep-learning service created by the cloud administrator. For this tutorial we leverage an example project developed in PyTorch, which is based on the [PyTorch Beginner Transfer Learning Tutorial](https://pytorch.org/tutorials/beginner/transfer_learning_tutorial.html).

We run through:

1. Loading the data into Azure Blob Store
2. Local debugging
3. Submitting a job to the deep-learning job service

## Prerequisites

You will need the following software installed:

* __Installed the Azure CLI 2.0 with version 0.3 or higher of the batchai module__ - see these [instructions](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
* __Powershell__ (future work is to replicate with bash scripts)
* __An IDE that supports Python__ - in this tutorial we leverage Visual Studio

This document assumes a cloud administrator has followed the [guide](cloud_admin_doc.md) for setting up the job-service. The cloud administrator should pass on to you the following information:

* The Azure resource group name
* The Batch AI workspace name
* The storage account name
* The storage account container name (this is the data lake that will host the unstructured data)

## Loading the data into Azure Blob Store

The problem we’re going to solve today is to train a model to classify ants and bees. We have about 120 training images each for ants and bees. There are 75 validation images for each class. Usually, this is a very small dataset to generalize upon, if trained from scratch. Since we are using transfer learning, we should be able to generalize reasonably well.

Follow these steps:

1. Download the dataset to your local drive from [here](https://download.pytorch.org/tutorial/hymenoptera_data.zip).
2. Extract the dataset
3. Using PowerShell, issue the following Azure CLI command to upload the directory into Blob (you may have to login first with `az login`). You will need to update anything in ```<>``` with your information
    ```
    az storage blob upload-batch -s <LOCAL_DIRECTORY>/hymenoptera_data -d <BLOB_DIRECTORY_LOCATION> --account-name <STORAGE_ACCOUNT_NAME>
    ```

## Installing PyTorch packages

The [PyTorch homepage](https://pytorch.org/) shows how to install the packages pertinent to your OS and Python version. On a Windows system with Anaconda installed (Python 3.6) the install would be:

```
conda install pytorch -c pytorch 
pip3 install torchvision
```

## Local debugging

Using your favourite editor:

1. Create an empty Python project
2. Add all the files contained in the [example_project](../example_project) directory that is part of this repo.
3. The PyTorchTransferLearning.py program expects 3 parameters:
    * ```--input_dir``` the directory path where the images are contained e.g. PATH/hymenoptera_data
    * ```--output_dir``` where the artefacts of the training e.g. models get stored
    * ```--epochs``` the number of epochs to run

In Visual Studio we can include the parameters in the project properties (right-click on project and select Properties:

<img src="img/proj_props.png?raw=true" alt="VS project properties" width="500px"/>

When you debug the job you should see the following console output:

<img src="img/local_console_out.png?raw=true" alt="Local Console Debug" width="300px"/>

Once we are happy with our code running on a small scale (i.e. 1 epoch or a small sample) we are ready to submit to a scalable backend (more epochs/more data). 

## Submitting a job

In this section we demonstrate how to submit a job to the deep-learning service. Before doing so, we run through some of the basics regarding Batch AI.

### Understanding Batch AI resources

The Batch AI resources are organised as follows:

![](img/batchai_hierachy.png?raw=true "Batch AI Resource Hierarchy")

A workspace is a container for _clusters_, _file servers_ and _experiments_ (which contain _jobs_). We would recommend having a seperate workspace for development, testing and production.

In the set up of this tutorial we have made a `dev` workspace and provisioned a GPU cluster called `dev-cluster-00` with __0 nodes__. When a job is submitted to the cluster, Batch AI will automatically resize the cluster to the pre-determined minimum size (>0). In the set up for this tutorial, the cluster will provision with an NC6 Azure VM (1 NVIDIA Tesla K80 GPU card) - it is possible to have other VMs with more GPUs (as of August 2018, the maximum is 4) and also more powerful GPUs. Please consult [this](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu) link to see the different GPU machines available. 

Whilst file servers and local storage on the compute nodes will be the optimized method for deep-learning training due to data locality, often unstructured data (images, video, sound, text) is stored in a data lake (Azure Blob storage). Typically the extra performance from NFS/local storage is not enough to compensate for the cost of data movement from the data lake to NFS/local storage. With this in mind, the set up for this tutorial uses Blob storage. When the cluster re-sizes from 0, Batch AI automatically mounts blob storage onto the nodes of the cluster for you and therefore treats the mount like a POSIX compliant store.

An *Experiment* is a resource that contains a log of all the job submissions to the service. For this tutorial, the PowerShell scripts (see below) will create an experiment automatically for you.

### Understanding the 01_JobSubmit PowerShell Script

In order to make the workflow of local->remote smooth we have provide a PowerShell Script called [01_JobSubmit.ps1](../example_project/01_JobSubmit.ps1) that:

* Creates an experiment
* Uploads the python script to the remote fileshare (which gets mounted to the GPU cluster)
* Creates a job (where the name is the timestamp) and submits
* Streams the remote console output
* Downloads artefacts in the `output-dir` and stores them in a `models` directory in your project (the script creates the `models` directory if necessary)
* Downloads logs and stores them in a logs directory in your project

In order for the PowerShell script to do this orchestration it requires things like your storage account name, Batch AI workspace name, etc. Therefore, it expects a __project.json__ file (please note that a project.json file is specific to this work and is not part of Batch AI). The template provided in this repo is as follows:

```
{
  "clusterName": "ENTER_THE_CLUSTER_NAME",
  "persistCluster": "False",
  "resourceGroup": "ENTER_RESOURCE_GROUP_NAME",
  "storageAccount": "ENTER_STORAGE_ACCOUNT",
  "blobContainerName": "ENTER_NAME_THAT_CONTAINS_THE_DATA",
  "experimentName": "ENTER_EXPERIMENT_NAME",
  "workspaceName": "dev",
  "sourceScript": "PyTorchTransferLearning.py",
  "sourceScriptFileShareDirectory": "scripts/pytorch",
  "monitorFileName": "stdout-0.txt",
  "logFileShareName": "logs",
  "maxNodes": 1
}
```
You should populate this with the information provided to you by your cloud administrator (we assume that you are working in `dev` workspace - you may need to update the `workspaceName` if your cloud administrator called it something different e.g. sandbox or test. In addition you should fill in the `experimentName` with the name of your experiment e.g. `ants_and_bees_classification`.

As we are not using Horovod, we have set the maxNodes to 1.

The `persistCluster` parameter can be `True` or `False`. When this is set to `False` the script will spin up the cluster (approx 5mins), run the job and resize the cluster to 0. If you intend to iterate on a model (e.g. change learning rate or momentum) then we would recommend setting `persistCluster` to `True` - this will keep the cluster up after your first job submission and will reduce the latency of further submissions because there is no need to spin up compute resources.

__REMEMBER: You should pause the cluster (i.e. resize to 0) when you have finished. We have created a 02_PauseCluster.ps1, which does exactly that__

The job.json file contains the parameters for the job:

```
{
    "$schema": "https://raw.githubusercontent.com/Azure/BatchAI/master/schemas/2018-05-01/job.json",
    "properties": {
      "nodeCount": 1,
      "pyTorchSettings": {
        "pythonScriptFilePath": "$AZ_BATCHAI_MOUNT_ROOT/logs/scripts/pytorch/PyTorchTransferLearning.py",
        "commandLineArgs": "--input_dir $AZ_BATCHAI_MOUNT_ROOT/datalake/hymenoptera_data --epochs 25 --output_dir $AZ_BATCHAI_MOUNT_ROOT/datalake/models"
      },
        "stdOutErrPathPrefix": "$AZ_BATCHAI_MOUNT_ROOT/logs",
        "containerSettings": {
            "imageSourceRegistry": {
                "image": "batchaitraining/pytorch:0.4.0-cp36-cuda9-cudnn7"
            }
        }
    }
}
```

For this tutorial there is nothing that requires updating. However, it is worth understanding that we need to include:

* The python file path - what needs to be executed
* Any command line arguments - note we have included our input directory and output directory that exist on blob storage.
* Container settings - there is a catalog of pre-configured containers on [Docker Hub](https://hub.docker.com/u/batchaitraining/) and you can also create your own containers hosted on Azure Container Registry (see [here](https://github.com/Azure/BatchAI/blob/master/documentation/using-azure-container-registry.md)).

The job.json file has more configuration settings that maybe useful as you get more into Batch AI e.g. job priority, etc - see the schema [here](https://github.com/Azure/BatchAI/blob/master/schemas/2018-05-01/job.json).

### Submit

You can submit the job by executing the PowerShell script. In Visual Studio this can be achieved by right-clicking on 01_JobSubmit.ps1 and selecting Execute File:

<img src="img/submit_job.png?raw=true" alt="Local Console Debug" width="700px"/>

You will then be presented with a PowerShell screen that is provisioning the job for you. You will see that the console hangs for a while on the following line:

<img src="img/job_provision.png?raw=true" alt="Local Console Debug" width="700px"/>

This is because it takes a few minutes to provision the backend cluster (<5mins). If you have set the `persistCluster` parameter in project.json to `True` then subsequent job submissions will have a latency of around 10secs before they start running. Once the job is running you will see the console streaming through the epochs:

<img src="img/console_streaming.png?raw=true" alt="Local Console Debug" width="300px"/>

Once the job has finished the model and log files are downloaded into your local project directory. Moreover - assuming you have not persisted the cluster - the compute resources on the backend will scale down to 0.

If you decided to persist the cluster then remember to run 02_PauseCluster.ps1 to resize the cluster back to 0 when you have finished.

#### Validating the model
We have provided a [jupyter notebook](../example_project/validate_model.ipynb) that imports the model built on the GPU cluster and tests the model on some local images (remember the model gets downloaded to the local machine as part of the job submission script). You will need to update the following variables:

<img src="img/model_name.png?raw=true" alt="Local Console Debug" width="800px"/>

Once all the cells have finished running you should see images with predictions:

<img src="img/predictions.png?raw=true" alt="Local Console Debug" width="600px"/>
