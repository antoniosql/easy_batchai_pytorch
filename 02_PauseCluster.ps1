$x = Get-Content -Raw -Path project.json | ConvertFrom-Json
"pausing cluster"
az batchai cluster auto-scale -g $x.resourceGroup -w $x.workspaceName -n $x.clusterName --min 0 --max $x.maxNodes