public class AccountNotesPrintableCtrl {
    public list<NoteWrapper> contentNotes{get;set;}
    public AccountNotesPrintableCtrl(Apexpages.StandardController sc)
    {
        Set<Id> noteIds = new Set<Id>();
        List<Account> acc = [Select id ,
                             (Select id from AttachedContentNotes)
                             from account
                             where id = :sc.getId()];
        for(AttachedContentNote n : acc[0].AttachedContentNotes)
        {
            noteIds.add(n.Id);
        }
        contentNotes = new List<NoteWrapper>();
        for (contentNote n : [Select id, Title, content, createddate, createdbyId, createdBy.Name, TextPreview , Owner.Name 
                              from ContentNote
                              where id in:noteIds order by createdDate desc])
        {
            NoteWrapper w = new NoteWrapper();
            w.note = n;
            w.content = n.content.toString().unescapeHtml4().unescapeHtml3().unescapeJava();
            contentNotes.add(w);
        }
    }
    public class NoteWrapper
    {
        public ContentNote note{get;set;}
        public String content{get;set;}
    }
}