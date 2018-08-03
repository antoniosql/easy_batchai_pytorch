# Setting up the deep-learning service

In order to accelerate setting up a deep-learning job service using Batch AI we have provided a PowerShell script called [00_CreateWorkspace.ps1](../cloud_admin_scripts/00_CreateWorkspace.ps1) that will provision a __sandbox environment to test and getting a better understanding of how Batch AI can be leverage to create such a service__.

The script is very simple:

* It creates a logs fileshare on the storage account (this is for storing log files)
* Creates a scripts directory on the fileshare (this is the location of where user python scripts will get uploaded to the service)
* Creates a Batch AI workspace called `dev`
* Creates a cluster in the `dev` workspace with 0 nodes (nodes get provisioned at job submission time) and mounts the fileshare and blob container (data lake)
    * the nodes are provisioned as low-priority


## Azure Batch AI Fundamentals
The Batch AI resources are organised as follows:

![](img/batchai_hierachy.png?raw=true "Batch AI Resource Hierarchy")

A workspace is a container for _clusters_, _file servers_ and _experiments_ (which contain _jobs_). We would recommend having a seperate workspace for development, testing and production.

In the set up of this tutorial we have made a `dev` workspace and provisioned a GPU cluster called `dev-cluster-00` with __0 nodes__. When a job is submitted to the cluster, Batch AI will automatically resize the cluster to the pre-determined minimum size (>0).

Whilst NFS and local storage on the compute nodes will be the optimized method for deep-learning training due to data locality, often unstructured data (images, video, sound, text) is stored in a data lake (Azure Blob storage). Typically the extra performance from NFS/local storage is not enough to compensate for the cost of data movement from the data lake to NFS/local storage. With this in mind, the set up for this tutorial uses Blob storage. When the cluster re-sizes from 0, Batch AI automatically mounts blob storage onto the nodes of the cluster for you and therefore treats the mount like a POSIX compliant store.

## Executing the 00_CreateWorkspace.ps1 Script

In the script you will notice some user-defined variables that need to be set:

```
# -- User Settings (REQUIRE CHANGING)
$RESOURCE_GROUP = "RESOURCE_GROUP_NAME"
$STORAGE_ACCOUNT = "STORAGE_ACCOUNT_NAME"
$BLOB_CONTAINER = "BLOB_CONTAINER_NAME_CONTAINING_THE_DATA"

# -- User Settings (GOOD DEFAULTS FOR A SANDBOX, BUT CAN BE CHANGED)
$WORKSPACE_NAME = "dev"
$VM_TYPE = "Standard_NC6"
$VM_PRIORITY = "lowpriority"
$MAX_NODES = 1 
$FILE_SHARE_NAME = "logs"
$FILE_SHARE_MNT = "logs"
$BLOB_MNT = "datalake"
$SCRIPTS_DIR_NAME = "scripts"
```

You should populate the:

* resource group - the Azure resource group for the Batch AI workspace
* storage account - this should be the storage account containing the data
* container - the blob container that is your data lake

Other settings that have been provided with 'good defaults' for a sandbox environment are:

* `$WORKSPACE_NAME` - the name of the Batch AI workspace. We have set this to be called `dev`.
* `$VM_TYPE` - the size of the VM. We have set this to be an NC6 Azure VM (1 NVIDIA Tesla K80 GPU card), please consult [this](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu) guide to find a more appropriate GPU-based VM.
* `$VM_PRIORITY` - this can be either "lowpriority" or "dedicated". For this sandbox environment we have set "lowpriority" - please consult [this](https://docs.microsoft.com/en-us/azure/batch/batch-low-pri-vms) guide to understand the differences and when to use which type.
* `$MAX_NODES` - the GPU cluster will auto-scale based on the queue of jobs. For this sandbox we have defaulted on 1 node - if there are many users we would recommend increasing the maximum number of nodes to the number of users.
* `$FILE_SHARE_NAME` - this is the name of the fileshare for storing logs and scripts.
* `$FILE_SHARE_MNT` - the mount point is given a special environment variable called `$AZ_BATCHAI_MOUNT_ROOT` that is accessible on the nodes. Therefore, users can point to the file share with `$AZ_BATCHAI_MOUNT_ROOT/FILE_SHARE_MNT` e.g. in our case the mount point for the logs would be `$AZ_BATCHAI_MOUNT_ROOT/logs`
* `$BLOB_MNT` - The mount point on the nodes for the blob storage container. This would be `$AZ_BATCHAI_MOUNT_ROOT/BLOB_MNT` or in our case `$AZ_BATCHAI_MOUNT_ROOT/datalake`
* `$SCRIPTS_DIR_NAME` - the directory name for the scripts on the file share. Note that when mounted on the nodes, this would look like `$AZ_BATCHAI_MOUNT_ROOT/FILE_SHARE_MNT/SCRIPTS_DIR_NAME` or in our case `$AZ_BATCHAI_MOUNT_ROOT/logs/scripts`