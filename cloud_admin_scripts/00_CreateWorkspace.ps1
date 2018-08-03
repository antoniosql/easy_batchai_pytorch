# In this script we:
# Generate a workspace and cluster with 0 nodes (this provides a serverless approach).
# This is a one time "platform deal"
# Assumes batchai account has been created

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

# create a file share for the logs+scripts on the storage account
az storage share create -n $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT

# create a scripts directory (if it does not exist)
$dir_exists = az storage directory exists -n $SCRIPTS_DIR_NAME -s $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT -o tsv
if($dir_exists -eq 'False'){
	Write-Host "creating scripts directory..."
	az storage directory create -n $SCRIPTS_DIR_NAME -s $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT
}
else{
	Write-Host "scripts directory already exists"
}

Write-Host "Creating workspace: " $WORKSPACE_NAME
az batchai workspace create -g $RESOURCE_GROUP -n $WORKSPACE_NAME

$cluster_name = $WORKSPACE_NAME+"-cluster-00"
Write-Host "Creating 0 node autoscale cluster called" $cluster_name

az batchai cluster create -n $cluster_name -g $RESOURCE_GROUP -w $WORKSPACE_NAME -s $VM_TYPE -t 0 --min 0 --max $MAX_NODES --generate-ssh-keys --vm-priority $VM_PRIORITY `
	--storage-account-name $STORAGE_ACCOUNT --afs-mount-path $FILE_SHARE_MNT --afs-name $FILE_SHARE_NAME --bfs-mount-path $BLOB_MNT --bfs-name $BLOB_CONTAINER



