public with sharing class AccountTriggerHandler implements TriggerContextAction.ContextAction {
    public void beforeInsert(List<Account> newList){
        for(Account newOpp:newList){
            newOpp.addError('Account can\'t be created');
        }
    }
    public void afterInsert(List<Account> newList){}
    public void beforeUpdate(List<Account> newList,List<Account> oldList){}
    public void afterUpdate(List<Account> newList,List<Account> oldList){}
    public void beforeDelete(List<Account> oldList){}
    public void afterDelete(List<Account> oldList){}
    public void afterUndelete(List<Account> oldList){}
}
