@isTest
private class WarehouseCalloutServiceTest {

    private static final Boolean expectedReplacement = true;
    private static final String expectedName = 'Generator 1000 kW';
    private static final String expectedSku = '100003';
    private static final Integer expectedMaintenanceperiod = 365;
    private static final Integer expectedLifespan = 120;
    private static final Integer expectedCost = 5000;
    private static final Integer expectedQuantity = 5;

    @isTest static void testWarehouse() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock()); 
        Test.startTest();
        WarehouseCalloutService.runWarehouseEquipmentSync();
        Test.stopTest();
        Product2 equipment = [SELECT Id, Current_Inventory__c, Replacement_Part__c, Name, Maintenance_Cycle__c, Lifespan_Months__c, Cost__c, Warehouse_SKU__c
                              FROM Product2];
        System.assertEquals(equipment.Current_Inventory__c, expectedQuantity);                
        System.assertEquals(equipment.Replacement_Part__c, expectedReplacement);
        System.assertEquals(equipment.Name, expectedName);
        System.assertEquals(equipment.Maintenance_Cycle__c, expectedMaintenanceperiod);
        System.assertEquals(equipment.Lifespan_Months__c, expectedLifespan);
        System.assertEquals(equipment.Cost__c, expectedCost);
        System.assertEquals(equipment.Warehouse_SKU__c, expectedSku);
    }
}