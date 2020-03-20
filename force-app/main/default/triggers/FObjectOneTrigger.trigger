trigger FObjectOneTrigger on FObjectOne__c (before insert) {
  if (Trigger.isInsert) {
    System.debug('>>> FObjectOneTrigger.Insert <<< ');
    Integer counter = 0;
    for (FObjectOne__c recordObj : Trigger.new) {
      counter++;
      if (String.isBlank(String.valueOf(recordObj.TestDecimal__c))) {
        recordObj.TestDecimal__c = counter;
      }
    }
  }
}