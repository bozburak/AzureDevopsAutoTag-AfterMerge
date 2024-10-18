Bu PowerShell betiği, Azure DevOps üzerinde belirli bir kullanıcıya atanmış ve "In Review" tag'ine sahip iş öğelerini (Work Items) sorgular. Bu iş öğelerine bağlı olan Pull Request'leri kontrol eder, eğer ilgili Pull Request tamamlanmış ve hedef branch "dev" ise, iş öğesinin etiketini ("In Review") kaldırıp, "Waiting Release" olarak günceller. Aşağıdaki işlemleri gerçekleştiren bir dizi adım içerir:

Azure DevOps API'si kullanılarak kullanıcıya atanmış ve "In Review" tag'ine sahip iş öğeleri çekilir.
Her bir iş öğesinin ilişkili Pull Request'leri kontrol edilir.
Eğer Pull Request tamamlanmışsa ve hedef branch "dev" ise, iş öğesinin "In Review" tag'ini kaldırır, "Waiting Release" tag'ini ekler.
Pull Request'lerin durumları kontrol edilerek, aktif ya da terk edilmiş olup olmadığı tespit edilir.

----------------------------------------------------------------------------------------------------


This PowerShell script queries Azure DevOps for work items that are assigned to a specific user and have the "In Review" tag. It checks for related Pull Requests for these work items. If the related Pull Request is completed and the target branch is "dev", it removes the "In Review" tag from the work item and adds the "Waiting Release" tag instead. The script performs the following steps:

It uses the Azure DevOps API to retrieve work items assigned to the specified user that have the "In Review" tag.
It checks each work item for associated Pull Requests.
If a Pull Request is completed and the target branch is "dev", it updates the work item by removing the "In Review" tag and adding the "Waiting Release" tag.
The status of Pull Requests is checked to determine if they are active or abandoned.
