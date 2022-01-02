public with sharing class AccountTriggerHandler implements TriggerContextAction.ContextAction {
    public void beforeInsert(List<opportunity> newList){}
    public void afterInsert(List<opportunity> newList){}
    public void beforeUpdate(List<opportunity> newList,List<opportunity> oldList){}
    public void afterUpdate(List<opportunity> newList,List<opportunity> oldList){}
    public void beforeDelete(List<opportunity> oldList){}
    public void afterDelete(List<opportunity> oldList){}
    public void afterUndelete(List<opportunity> oldList){}
}
