public with sharing class EventCheckinController {

  public list<SelectOption> filterOptions {get; private set;}
  public decimal totalGuests {get;set;}
  public decimal totalCheckedIn {get;set;}

  public static String filter {get{
          if(ApexPages.CurrentPage().getParameters().get('filter') != null){
            return ApexPages.CurrentPage().getParameters().get('filter');
          } else{
            return null;
          }
        }}

  public CampaignMember[] allMembers {get;set;}

  public NewContact newContact {get;set;}

  private static id CampaignID {get{
    return (id)Event_Check_In_Settings__c.getOrgDefaults().get('Campaign_Id__c');
  }}

  public EventCheckinController() {
    getCampaignMembers();
    fillFilterList();
    newContact = new NewContact();
  }

  public void getCampaignMembers(){
    allMembers = [select Id, Status, Notes__c,
                Contact.FirstName, Contact.LastName,
                Guest_Host__c, Guest_Host__r.FirstName, Guest_Host__r.LastName,
                Number_of_Guests__c, Guests_Checked_In__c, Remaining_Check_Ins__c 
              from CampaignMember
              where Campaignid = :CampaignID];
    AggregateResult ar = [select sum(Number_of_Guests__c) totalGuests, sum(Guests_Checked_In__c) totalCheckedIn from CampaignMember where Campaignid = :CampaignID ];
    totalGuests = (decimal)ar.get('totalGuests');
    totalCheckedIn = (decimal)ar.get('totalCheckedIn');
  }

  public void fillFilterList(){
    set<String> filterSet = new set<String>();
    for(CampaignMember cm :allMembers){
      if(cm.Guest_Host__c!=null){
        filterSet.add(cm.Guest_Host__r.FirstName+' '+cm.Guest_Host__r.LastName);
      }
    }
    list<String> filterList = new list<String>(filterSet);
    filterList.sort();
    filterOptions = new list<SelectOption>();
    if (filterList.isEmpty()) 
      filterList.add('All');
    else 
      filterList.add(0, 'All');

    for (String s : filterList)
      filterOptions.add(new SelectOption(s, s));
  }

  @RemoteAction
  public static Database.SaveResult saveMember( String projectJson ) {  //Id projectId, String projectHealth, Date start, Date end ) 
    CampaignMember cm = ((CampaignMember)(JSON.deserialize(projectJson, CampaignMember.class)));
    if (cm.id == null)
      return null;
    else{
      CampaignMember cmToUpdate = [select Id, Status, Notes__c,
                Contact.FirstName, Contact.LastName,
                Guest_Host__c, Guest_Host__r.FirstName, Guest_Host__r.LastName,
                Number_of_Guests__c, Guests_Checked_In__c, Remaining_Check_Ins__c 
              from CampaignMember
              where id =: cm.id];
      cmToUpdate.Notes__c = cm.Notes__c;
      if(cm.Guests_Checked_In__c != null){
        cmToUpdate.Guests_Checked_In__c = cmToUpdate.Guests_Checked_In__c + cm.Guests_Checked_In__c;
      }
      return (Database.update( cmToUpdate, true ));
    }
  }

  @RemoteAction
  public static Database.SaveResult saveNewContact( String projectJson ) {  //Id projectId, String projectHealth, Date start, Date end ) 
    boolean success = false;
    NewContact c = ((NewContact)(JSON.deserialize(projectJson, NewContact.class)));
    if (c.lastName == null)
      return null;
    else{
      Contact newCon = new Contact();
      newCon.FirstName = c.FirstName;
      newCon.LastName = c.LastName;
      newCon.npe01__HomeEmail__c = c.Email;
      newCon.npe01__Preferred_Email__c = 'Personal';
      Database.SaveResult sr = Database.insert(newCon, true);
      CampaignMember newCM = new CampaignMember(campaignID = campaignID, contactID = newCon.id, status = (string)Event_Check_In_Settings__c.getOrgDefaults().get('Default_Status__c'), Number_of_Guests__c = c.numberGuests, Guests_Checked_In__c = c.guestsCheckedIn, Notes__c = c.Notes);
      Database.insert(newCM, true);
      return (sr);
    }
  }

  public class NewContact{
    public string FirstName {get;set;}
    public string LastName {get;set;}
    public string Email {get;set;}
    public integer numberGuests {get;set;}
    public integer guestsCheckedIn {get;set;}
    public string notes {get;set;}
  }

}