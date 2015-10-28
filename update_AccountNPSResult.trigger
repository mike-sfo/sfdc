trigger update_AccountNPSResult on Task (after insert, after update, after delete, after undelete) {

    list<Account> accountsToUpdate = new list<Account>();
    Account acc;
    
    System.Debug('>>>> starting');
    
    If (Trigger.isUpdate || Trigger.isInsert || Trigger.isUndelete) {
        for(Task newTask : Trigger.new) {
            If(newTask.Type == 'NPS Survey') {
                acc = new Account(Id = newTask.WhatId);
                
                //go through related NPS based tasks, get most recent
                List<Task> relatedTasks = [select ActivityDate, Customer_Response__c from Task where Type='NPS Survey' and WhatId=:acc.Id order by ActivityDate desc Limit 1];
    
                //for insert, update and undelete there will always be at least one record, insert, update, or undelete
                acc.NPS_Score__c = relatedTasks[0].Customer_Response__c;
                acc.Last_NPS_date__c = relatedTasks[0].ActivityDate;
                
                accountsToUpdate.add(acc);
            } 
        } 
    } else if (Trigger.isDelete) {
        for(Task oldTask : Trigger.old) {
            If(oldTask.Type == 'NPS Survey') {
                acc = new Account(Id = oldTask.WhatId);
                
                //go through related NPS based tasks, get most recent
                List<Task> relatedTasks = [select ActivityDate, Customer_Response__c from Task where Type='NPS Survey' and WhatId=:acc.Id order by ActivityDate desc Limit 1];
    
                If (relatedTasks.size() == 0) { //no records returned, all have been deleted
                    acc.NPS_Score__c = '';
                    acc.Last_NPS_date__c = NULL;
                } else {
                    //if there is an available record, write that data
                    acc.NPS_Score__c = relatedTasks[0].Customer_Response__c;
                    acc.Last_NPS_date__c = relatedTasks[0].ActivityDate;
                } 
                accountsToUpdate.add(acc);
            } 
        }
    }
    // Update all accounts in our list
    try
    {
        //sets have no duplicates, assign to set, duplicates will be removed
        Set<Account> myset = new Set<Account>();
        List<Account> result = new List<Account>();    
        myset.addAll(accountsToUpdate);
        result.addAll(myset);

        update result;
    }
    catch (DMLException ex) {}
}
