/**
 * @File Name          : FetchCustomPermissions.cls
 * @Description        : Class to query if user has custom permissions
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/16/2019, 11:22:15 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/16/2019, 11:12:21 AM   Seth Boyd     Initial Version
**/
public with sharing class FetchCustomPermissions {
    @AuraEnabled(cacheable=True)
    public static Map<String, Boolean> fetchCustomPermissions(String[] permissions) {
        Map<String, Boolean> permMap = new Map<String, Boolean>();
        for (String perm : permissions) {
            permMap.put(perm, FeatureManagement.checkPermission(perm));
        }

        return permMap;
    }
}