$jn=Get-Date -Format yyyyMMddHHmmss

$x = Get-Content -Raw -Path project.json | ConvertFrom-Json
"Creating job using following project file parameters..."
echo $x

# re-size cluster if persistCluster == True, so that the minimum cluster size is 1
$clusterlist = az batchai cluster list -g batchai -w dev | ConvertFrom-Json
if($x.persistCluster -eq 'True' -and ($($clusterlist.scaleSettings.autoScale.minimumNodeCount) -eq 0 -or [string]::IsNullOrEmpty($clusterlist.scaleSettings.autoScale))){
	"re-scaling cluster"
	az batchai cluster auto-scale -g $x.resourceGroup -w $x.workspaceName -n $x.clusterName --min 1 --max $x.maxNodes
}
else{
	"cluster already has nodes or you are submitting a serverless job"
}

# create the experiment, if it does not exist
$experiments = az batchai experiment list -g $x.resourceGroup -w $x.workspaceName -o json | ConvertFrom-Json
$experimentNames = @('', $experiments.name)
# if there is no experiment then we need to create it
if($experimentNames.Contains($x.experimentName) -eq 0){
	"experiment does not exist, therefore creating"
	az batchai experiment create -g $x.resourceGroup -w $x.workspaceName -n $x.experimentName
}

"uploading script..."
az storage file upload -s $x.logFileShareName --source $x.sourceScript --path $x.sourceScriptFileShareDirectory --account-name $x.storageAccount
"creating job: $jn..."
az batchai job create -c $x.clusterName -n $jn -g $x.resourceGroup -w $x.workspaceName -e $x.experimentName -f job.json --storage-account-name $x.storageAccount
az batchai job file stream -j $jn -g $x.resourceGroup -w $x.workspaceName -e $x.experimentName -f $x.monitorFileName

# create a logs directory (if it does not exist)
New-Item -ItemType Directory -Force -Path logs
# create a models directory (if it does not exist)
New-Item -ItemType Directory -Force -Path models
# download model 
"download pytorch model"
az storage blob download -c $x.blobContainerName -f ./models/$jn.pt -n models/mymodel.pt --account-name $x.storageAccount
"download logs"
az storage file download-batch -d ./logs -s $x.logFileShareName --account-name $x.storageAccount --pattern */batchai/workspaces/$($x.workspaceName)/experiments/$($x.experimentName)/jobs/$jn/*