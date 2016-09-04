public class MaintenanceRequestHelper {
    
    private static final String REQUEST_TYPE = 'Routine Maintenance';
    private static final String NEW_STATUS = 'New';
    private static final String REQUEST_SUBJECT = 'routine checkup';
    private static final String REQUEST_ORIGIN = 'Web';
    private static final String CLOSED = 'Closed';
    private static final String REPAIR = 'Repair';
    private static final String ROUTINE_MAINTENANCE = 'Routine Maintenance';
    private static List<Work_Part__c> requestWorkParts;
    
    public static void updateWorkOrders(Map<Id, Case> oldMaintenanceRequestMap, Map<Id, Case> newMaintenanceRequestMap) {
        requestWorkParts = new List<Work_Part__c>();
        Map<Id, Case> oldIdNewRequest = new Map<Id, Case>();
        List<Case> insertCaseList  = new List<Case>();
        List<Work_Part__c> allWorkParts = [SELECT Maintenance_Request__c, Equipment__r.Maintenance_Cycle__c 
                                           FROM Work_Part__c 
                                           WHERE Maintenance_Request__c =: oldMaintenanceRequestMap.keySet()];
        for (Id oldRequestId : oldMaintenanceRequestMap.keySet()) {
            Case oldRequest = oldMaintenanceRequestMap.get(oldRequestId);
            Case newRequest = newMaintenanceRequestMap.get(oldRequestId);
            if ( (oldRequest.Status != CLOSED) && 
                 (newRequest.Status == CLOSED) &&
                 ( (oldRequest.Type == REPAIR) || (oldRequest.Type == ROUTINE_MAINTENANCE) ) ) {
                
                Case newMaintenanceRequest = createNewRequest(oldRequest, calculateMaintenanceCycle(oldRequestId, allWorkParts));
                oldIdNewRequest.put(oldRequestId, newMaintenanceRequest);
                insertCaseList.add(newMaintenanceRequest);
            }
        }

        insert insertCaseList; 

        for (Work_Part__c workPart : requestWorkParts) {
            workPart.Maintenance_Request__c = oldIdNewRequest.get(workPart.Maintenance_Request__c).Id;
        } 
        update allWorkParts;  
    }

    private static Date calculateMaintenanceCycle(Id oldRequestId, List<Work_Part__c> allWorkParts) {
        for(Work_Part__c wp : allWorkParts) {
            if (wp.Maintenance_Request__c == oldRequestId) {
                requestWorkParts.add(wp);
            }
        }
        List<Decimal> maintenanceCycleDays = new List<Decimal>();
        Integer shortestMaintenanceCycleDay = 0;
        if (requestWorkParts.size() > 0) {
            for (Work_Part__c wp : allWorkParts) {
                maintenanceCycleDays.add(wp.Equipment__r.Maintenance_Cycle__c);
            }
            maintenanceCycleDays.sort();
            shortestMaintenanceCycleDay = maintenanceCycleDays[0].intValue();
        }
        Date maintenanceCycleDate = Date.today().addDays(shortestMaintenanceCycleDay);
        return maintenanceCycleDate;
    } 

    private static Case createNewRequest(Case oldRequest, Date maintenanceCycleDate) {
        Id vehicle = oldRequest.Vehicle__c; 
        Id equipment = oldRequest.Equipment__c;
        String requestOrigin = oldRequest.Origin;
        String requestSubject = String.isBlank(oldRequest.Subject) ? REQUEST_SUBJECT : oldRequest.Subject;
        Date reportDate = Date.today();
        Case newRequest = new Case(Type = REQUEST_TYPE, 
                                   Subject = requestSubject,  
                                   Origin = requestOrigin,
                                   Status = NEW_STATUS,
                                   Equipment__c = equipment,
                                   Date_Reported__c = reportDate,  
                                   Vehicle__c = vehicle,
                                   Date_Due__c = maintenanceCycleDate);
        return newRequest;
    }
}        