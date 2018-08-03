# Setting up the deep-learning service 

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