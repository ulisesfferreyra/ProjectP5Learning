trigger updateStatus on Unit_Progress__c (after update) {
    if(Trigger.isAfter){
        updateStatusHelper.updateUserUnitProg(Trigger.new);
    }
}