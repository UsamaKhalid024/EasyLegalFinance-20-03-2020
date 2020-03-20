public with sharing class PermissionAssigner {
    private Permission_Assignment__mdt[] permissionionSetAssignments {
        get {
            if (this.permissionionSetAssignments == null)
                this.permissionionSetAssignments = [Select User_Field_Name__c, Permission_Set_Name__c From Permission_Assignment__mdt];
            return permissionionSetAssignments;
        }
        private set;
    }
    /*
    private Map<String, String> permissionionSetAssignmentsMap {
        get {
            if (permissionionSetAssignmentsMap = null) {
                permissionionSetAssignmentsMap = new Map<String, String>();
                for (Permission_Assignment__mdt pa : permissionionSetAssignments) {
                    permissionionSetAssignmentsMap.insert(pa.User_Field_Name__c, Permission_Set_Name__c);
                }
            }

            return permissionionSetAssignmentsMap;
        }
    }
    */
    private Set<String> requiredPermissionSetNames = new Set<String>();
    private Map<String, Id> psNameIdMap = new Map<String, Id>(); // <UserId, PermissionName>
    private Map<Id, String[]> addPermissions = new Map<Id, String[]>(); // <UserId, PermissionName>
    private Map<Id, String[]> removePermissions = new Map<Id, String[]>(); // <UserId, PermissionName>

    private Map<Id, User> oldMap; // = new Map<Id, User>();
    private Map<Id, User> newMap; // = new Map<Id, User>();

    public PermissionAssigner(Map<Id, User> oldMap, Map<Id, User> newMap) {
        // Intended to be called from trigger
        this.oldMap = oldMap;
        this.newMap = newMap;
        //private Map<Id, User> newMap; = new Map<Id, User>();
    }

    private void findPermissionsChanges() {
        User oldUser = null;
        for (User u : newMap.values()) {
            if (oldMap != null && oldMap.containsKey(u.Id)) {
                oldUser = oldMap.get(u.Id);
                // User has been modified, so modify permissions if they have User field changed
                for (Permission_Assignment__mdt pa : this.permissionionSetAssignments) {
                    if (u.get(pa.User_Field_Name__c) != oldUser.get(pa.User_Field_Name__c)) {
                        // Field has changed
                        if (u.get(pa.User_Field_Name__c) == true) {
                            if (!addPermissions.containsKey(u.Id)) {
                                addPermissions.put(u.Id, new String[]{});
                            }
                            addPermissions.get(u.Id).add(pa.Permission_Set_Name__c);
                            requiredPermissionSetNames.add(pa.Permission_Set_Name__c);
                        } else {
                            if (!removePermissions.containsKey(u.Id)) {
                                removePermissions.put(u.Id, new String[]{});
                            }
                            removePermissions.get(u.Id).add(pa.Permission_Set_Name__c);
                            requiredPermissionSetNames.add(pa.Permission_Set_Name__c);
                        }
                    }
                }

            } else {
                // User is new, so add permissions if the User field is true 
                oldUser = null;

                for (Permission_Assignment__mdt pa : this.permissionionSetAssignments) {
                    if (u.get(pa.User_Field_Name__c) == true) {
                        // Field is true
                        if (!addPermissions.containsKey(u.Id)) {
                            addPermissions.put(u.Id, new String[]{});
                        }
                        addPermissions.get(u.Id).add(pa.Permission_Set_Name__c);
                        requiredPermissionSetNames.add(pa.Permission_Set_Name__c);
                    }
                }
            }
        }
    }

    public void applyPermissionsChanges() {
        this.findPermissionsChanges();
        if (requiredPermissionSetNames.size() > 0) {
            futureApplyPermissionsChanges(this.requiredPermissionSetNames, JSON.serialize(this.addPermissions), JSON.serialize(this.removePermissions));
        }
    }

    @future
    private static void futureApplyPermissionsChanges(
        Set<String> requiredPermissionSetNames,
        String addPermissionsJson,
        String removePermissionsJson
    ) {
        Map<Id, String[]> addPermissions = (Map<Id, String[]>) JSON.deserialize(addPermissionsJson, Map<Id, String[]>.class);
        Map<Id, String[]> removePermissions = (Map<Id, String[]>) JSON.deserialize(removePermissionsJson, Map<Id, String[]>.class);
        Map<String, Id> psNameIdMap = fetchPermissionSets(requiredPermissionSetNames);
        if (addPermissions.size() > 0) {
            addPermissionsChanges(psNameIdMap, addPermissions);
        }
        if (removePermissions.size() > 0) {
            removePermissionsChanges(psNameIdMap, removePermissions);
        }
    }

    private static Map<String, Id> fetchPermissionSets(Set<String> requiredPermissionSetNames) {
        Map<String, Id> psNameIdMap = new Map<String, Id>(); // <UserId, PermissionName>
        for (PermissionSet ps : [Select Id, Name From PermissionSet Where Name in :requiredPermissionSetNames]) {
            psNameIdMap.put(ps.Name, ps.Id);
        }
        return psNameIdMap;
    }

    private static void addPermissionsChanges(Map<String, Id> psNameIdMap, Map<Id, String[]> addPermissions) {
        PermissionSetAssignment[] psaList = new PermissionSetAssignment[]{};
        for (Id uid : addPermissions.keySet()) {
            for (String psName : addPermissions.get(uid)) {
                psaList.add(new PermissionSetAssignment(AssigneeId=uid, PermissionSetId=psNameIdMap.get(psName)));
            }
        }
        Database.upsert(psaList, false);
    }

    private static void removePermissionsChanges(Map<String, Id> psNameIdMap, Map<Id, String[]> removePermissions) {
        String[] filters = new String[]{};
        for (Id uid : removePermissions.keySet()) {
            for (String psName : removePermissions.get(uid)) {
                String filter = '(AssigneeId = \'' + uid + '\' AND PermissionSetId = \'' + psNameIdMap.get(psName) + '\')';
                system.debug(filter);
                filters.add(filter);
            }
        }
        String queryStr = 'Select Id From PermissionSetAssignment Where ' + String.join(filters, ' OR ');

        PermissionSetAssignment[] psaList = Database.query(queryStr);
        system.debug(psaList);
        Database.delete(psaList, false);
    }
}