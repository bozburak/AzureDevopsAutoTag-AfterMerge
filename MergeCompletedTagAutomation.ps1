# Personal Access Token (PAT) ve gerekli değişkenler
$personalAccessToken = ""  # Azure DevOps için Personal Access Token
$organization = ""  # Azure DevOps organizasyonunuzun adı
$project = ""  # Projenizin adı
$userName = "Burak BOZ"  # İş öğesi Burak BOZ'a atanmış olanları hedefliyoruz

# API URL'lerini Tanımla
$baseUrl = "https://dev.azure.com/$organization/$project/_apis/wit/wiql?api-version=6.0"
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$personalAccessToken"))
}

# Wiql Sorgusu: Kullanıcıya atanmış ve 'In Review' veya 'InReview' tag'lerine sahip work item'ları çek
$wiqlQuery = @"
{
    "query": "SELECT [System.Id], [System.Tags], [System.AssignedTo] FROM WorkItems WHERE [System.AssignedTo] = '$username' AND ([System.Tags] CONTAINS 'In Review')"
}
"@

# 1. Sorguyu Çalıştır
$workItemsResponse = Invoke-RestMethod -Uri $baseUrl -Headers $headers -Method Post -Body $wiqlQuery -ContentType "application/json"


# Eğer work item yoksa hata ver.
if (-not $workItemsResponse.workItems) {
    Write-Host "No work items found with 'In Review' tags for the user $username."
    return
}

# 2. Work item'ları işle
foreach ($workItem in $workItemsResponse.workItems) {
    $workItemId = $workItem.id
    $workItemDetailsUrl = "https://dev.azure.com/$organization/$project/_apis/wit/workitems/$($workItemId)?api-version=6.0&`$expand=all"
    $workItemDetails = Invoke-RestMethod -Uri $workItemDetailsUrl -Headers $headers -Method Get
    
    # Pull Request'e bağlı relations'ları bul
    $relatedPullRequests = @()
    foreach ($relation in $workItemDetails.relations) {
        if ($relation.rel -eq "ArtifactLink" -and $relation.url -like "*pullrequest*") {
            # Pull Request URL'si, relation.url alanında yer alır
            $relatedPullRequests += $relation.url
        }
    }

    # Eğer pull request'ler varsa, bunları yazdır

    
    Write-Host "-----------------------------------------"
    if ($relatedPullRequests.Count -gt 0) {
        Write-Host "Work item ID: $workItemId için ilişkili Pull Request'ler:"
        foreach ($prUrl in $relatedPullRequests) {
            # Pull Request ID'sini URL'den çıkarıyoruz
            $decodedUrl = $prUrl -replace '%2F', '/'

            # %2F'yi takip eden kısmı almak için URL'yi / ile bölelim
            $splitUrl = $decodedUrl -split '/'

            # Son elemanı al (ID kısmı)
            $lastId = $splitUrl[-1]

            # Sonucu yazdır
            Write-Output "Or ID: $lastId"

            # Pull Request detaylarını almak için API URL'si
            $prDetailsUrl = "https://dev.azure.com/$organization/$project/_apis/git/repositories/***repositoryId***/pullRequests/$($lastId)?api-version=6.0"
            
            $prDetails = Invoke-RestMethod -Uri $prDetailsUrl -Headers $headers -Method Get

            # PR'in merge edilip edilmediğini kontrol et
            $targetBranch = $prDetails.targetRefName -replace "refs/heads/", ""
            
            Write-Host "Hedef branch: $targetBranch"
            if ($prDetails.status -eq "completed" -and $targetBranch -eq "dev") {
                Write-Host "Pull Request ID: $workItemId merge edilmiş ve hedef branch: dev"

                # "In Review" tag'ini kaldır, "Waiting Release" tag'ini ekle
                $workItemUpdateUrl = "https://dev.azure.com/$organization/$project/_apis/wit/workitems/$($workItemId)?api-version=6.0"
                
                Write-Host "Pull Request ID: $workItemUpdateUrl"
                # Tag'leri güncellemek için JSON payload
                $jsonPatch = 
                    @(@{
                                op    = "add"
                                path  = "/fields/System.Tags"
                                value = "Waiting Release"
                            })

                $removePatch =
                @(@{
                                op    = "remove"
                                path  = "/fields/System.Tags"
                            })

                

                # Work item'ı güncelle
                $jsonTagBody = ConvertTo-Json -InputObject $jsonPatch
                $removeJsonTagBody = ConvertTo-Json -InputObject $removePatch
                $response = Invoke-RestMethod -Uri $workItemUpdateUrl -Headers $headers -Method Patch -Body $removeJsonTagBody -ContentType "application/json-patch+json"
                $response = Invoke-RestMethod -Uri $workItemUpdateUrl -Headers $headers -Method Patch -Body $jsonTagBody -ContentType "application/json-patch+json"
                
                Write-Host "Work item ID: $workItemId tag'leri güncellendi: In Review kaldırıldı, Waiting Release eklendi."
            } elseif ($prDetails.status -eq "active") {
                Write-Host "Pull Request ID: $prId halen aktif."
            } elseif ($prDetails.status -eq "abandoned") {
                Write-Host "Pull Request ID: $prId terk edilmiş."
            } else {
                Write-Host "Pull Request ID: $prId için bilinmeyen durum: $($prDetails.status)."
            }
            Write-Host "-----------------------------------------"
        }
    } else {
        Write-Host "Work item ID: $workItemId için ilişkili bir Pull Request bulunamadı."
    }
}