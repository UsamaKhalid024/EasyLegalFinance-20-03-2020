import { LightningElement, api, track } from 'lwc';

export default class FundingDetailsChequeGroup extends LightningElement {
    @api grouping;
    @api getData() {
        return this.dataTable.data
    }

    @track columns = [
        { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
        { label: 'Client Account', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.Name'}}, sortable: true },
        { label: 'File #', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.AccountNumber'}}, sortable: true },
        //{ label: 'Account Address', fieldName: 'account.BillingAddress', type: 'address', },
        //{ label: 'Contact Address', fieldName: 'account.Primary_Contact__r.MailingAddress', type: 'address' },
        { label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c', type: 'text' },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
        { label: 'CHQ #', fieldName: 'Cheque_Number__c', type: 'text', sortable: true, editable: true },
    ];

    @track _errors;
    @api 
    get errors() {
        return this.dataTable.errors
    }
    set errors(value) {
        this._errors = value;
    }

    @track _draftValues;
    @api 
    get draftValues() {
        return this.dataTable.draftValues
    }
    set draftValues(value) {
        this._draftValues = value;
    }

    @track _selectedRows;
    @api 
    get selectedRows() {
        return this.dataTable.selectedRows
    }
    set selectedRows(value) {
        this._selectedRows = value;
    }

    get dataTable() {
        return this.template.querySelector('lightning-datatable');
    }

    handleSetCHQClick(event) {
        let _draftValues = [...this.dataTable.draftValues] || [];

        this.dataTable.selectedRows.forEach(id => {
            const idx = _draftValues.findIndex(record => {return record.Id === id});
            if (idx >= 0) {
                _draftValues[idx].Cheque_Number__c = this.chqNum;
            } else {
                _draftValues.push({Id: id, Cheque_Number__c: this.chqNum});
            }
        });
        this.draftValues = _draftValues;
        //this.dt.draftValues = this.draftValues;
    }

    handleCHQChange(event) {
        this.chqNum = event.detail.value;
    }

}