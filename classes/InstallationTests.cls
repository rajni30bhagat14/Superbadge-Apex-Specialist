@IsTest
private class InstallationTests {

    private static final String STRING_TEST = 'TEST';
    private static final String NEW_STATUS = 'New';
    private static final String WORKING = 'Working';
    private static final String CLOSED = 'Closed';
    private static final String REPAIR = 'Repair';
    private static final String REQUEST_ORIGIN = 'Web';
    private static final String REQUEST_TYPE = 'Routine Maintenance';
    private static final String REQUEST_SUBJECT = 'AMC Spirit';
    public static String CRON_EXP = '0 0 1 * * ?';


    static testmethod void testMaintenanceRequestPositive() {
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        Id vehicleId = vehicle.Id;

        Product2 equipment = createEquipment();
        insert equipment;
        Id equipmentId = equipment.Id;

        Case r = createMaintenanceRequest(vehicleId, equipmentId);
        insert r;
        Work_Part__c w = createWorkPart(equipmentId, r.Id);
        insert w;

        Test.startTest();
        r.Status = CLOSED;
        update r;
        Test.stopTest();

        Case newRequest = [SELECT Id, Subject, Type, Equipment__c, Date_Reported__c, Vehicle__c, Date_Due__c
                           FROM Case 
                           WHERE Status =: NEW_STATUS];
        Work_Part__c workPart = [SELECT Id
                                 FROM Work_Part__c
                                 WHERE Maintenance_Request__c =: newRequest.Id];
        System.assert(workPart != null);
        System.assertEquals(newRequest.Type, REQUEST_TYPE);
        System.assert(newRequest.Subject != null);
        System.assertEquals(newRequest.Equipment__c, equipmentId);
        System.assertEquals(newRequest.Vehicle__c, vehicleId);
        System.assertEquals(newRequest.Date_Reported__c, System.today());
    }

    static testmethod void testMaintenanceRequestNegative() {
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        Id vehicleId = vehicle.Id;

        Product2 equipment = createEquipment();
        insert equipment;
        Id equipmentId = equipment.Id;

        Case r = createMaintenanceRequest(vehicleId, equipmentId);
        insert r;
        Work_Part__c w = createWorkPart(equipmentId, r.Id);
        insert w;

        Test.startTest();
        r.Status = WORKING;
        update r;
        Test.stopTest();

        List<Case> allRequest = [SELECT Id
                                 FROM Case];
        Work_Part__c workPart = [SELECT Id
                                 FROM Work_Part__c
                                 WHERE Maintenance_Request__c =: r.Id];
        System.assert(workPart != null);
        System.assert(allRequest.size() == 1);
    }

    static testmethod void testMaintenanceRequestBulk() {
        List<Vehicle__c> vehicleList = new List<Vehicle__c>();
        List<Product2> equipmentList = new List<Product2>();
        List<Work_Part__c> workPartList = new List<Work_Part__c>();
        List<Case> requestList = new List<Case>();
        List<Id> oldRequestIds = new List<Id>();

        for (Integer i = 0; i < 300; i++) {
            vehicleList.add(createVehicle());
            equipmentList.add(createEquipment());
        }
        insert vehicleList;
        insert equipmentList;

        for (Integer i = 0; i < 300; i++) {
            requestList.add(createMaintenanceRequest(vehicleList.get(i).Id, equipmentList.get(i).Id));
        }
        insert requestList;
        
        for (Integer i = 0; i < 300; i++) {
            workPartList.add(createWorkPart(equipmentList.get(i).Id, requestList.get(i).Id));
        }
        insert workPartList;
   
        Test.startTest();
        for (Case req : requestList) {
            req.Status = CLOSED;
            oldRequestIds.add(req.Id);
        }
        update requestList;
        Test.stopTest();

        List<Case> allRequest = [SELECT Id
                                 FROM Case
                                 WHERE Status =: NEW_STATUS];
        List<Work_Part__c> workParts = [SELECT Id
                                        FROM Work_Part__c
                                        WHERE Maintenance_Request__c IN: oldRequestIds];
        System.assert(allRequest.size() == 300);
        System.assert(workParts.size() == 0);
    }

    static testmethod void testWarehouseSync() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        String jobId = System.schedule('WarehouseSyncSchedule',
                                       CRON_EXP, 
                                       new WarehouseSyncSchedule());   
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE id = :jobId];

        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }    


    private static Vehicle__c createVehicle() {
        Vehicle__c v = new Vehicle__c(Name = STRING_TEST);
        return v;
    }

    private static Product2 createEquipment() {
        Product2 p = new Product2(Name = STRING_TEST,
                                  Lifespan_Months__c = 10,
                                  Maintenance_Cycle__c = 10,
                                  Replacement_Part__c = true);
        return p;
    }

    private static Case createMaintenanceRequest(Id vehicleId, Id equipmentId) {
        Case c = new Case(Type = REPAIR,
                          Status = NEW_STATUS,
                          Origin = REQUEST_ORIGIN,
                          Subject = REQUEST_SUBJECT,
                          Equipment__c = equipmentId,
                          Vehicle__c = vehicleId);
        return c;
    }

    private static Work_Part__c createWorkPart(Id equipmentId, Id requestId) {
        Work_Part__c wp = new Work_Part__c(Equipment__c = equipmentId,
                                           Maintenance_Request__c = requestId);
        return wp;
    }
}