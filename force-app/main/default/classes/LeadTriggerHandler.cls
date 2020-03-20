public class LeadTriggerHandler {
    public static void renameNewlyCreatedOppty(List<Lead> leads, Map<Id,Lead> oldLeads)
    {
        List<Opportunity> oppties = new List<Opportunity>();
        for(Lead l : leads)
        {
            if(l.isConverted == true && l.isConverted != oldLeads.get(l.Id).isConverted)
            {
                Opportunity opp = new Opportunity(Id = l.ConvertedOpportunityId);
                opp.Name = '';
                opp.Name = opp.Name + (!String.isEmpty(l.FirstName) ? l.FirstName+' ' : '');
                opp.Name = opp.Name + (!String.isEmpty(l.MiddleName) ? l.MiddleName.subString(0,1).toupperCase() +'. ' : '');
                opp.Name = opp.Name + (!String.isEmpty(l.LastName) ? l.LastName : '');
                
                oppties.add(opp);
            }
        }
        if(!oppties.isEmpty())
        {
            update oppties;
        }
    }
}