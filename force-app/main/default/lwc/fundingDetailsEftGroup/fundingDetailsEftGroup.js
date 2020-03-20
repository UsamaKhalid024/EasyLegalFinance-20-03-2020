import { LightningElement, api, track } from 'lwc';

export default class FundingDetailsEFTGroup extends LightningElement {
    @api grouping;
    @api getData() {
        return this.dataTable.data
    }

    @track columns = [
        //{ label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
        { label: 'File #', fieldName: 'opportunity.Account.AccountNumber', type: 'text', sortable: true },
        { label: 'Client Account', fieldName: 'client_account_url', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.Name'}}, sortable: true },
        { label: 'Payment Account', fieldName: 'Current_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Account_Name__c'}}, sortable: true },
        { label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        { label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c', type: 'text' },
        //{ label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        //{ label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Paid Date', fieldName: 'Sent_to_Bank_Date__c', type: 'date-local', sortable: true },
        { label: 'Paid By', fieldName: 'Sent_to_Bank_By__r.Name', sortable: true },
        //{ label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true, },
        { label: 'Payment File #', fieldName: 'File_Number__c', type: 'text', sortable: true },
        { label: 'Transaction Number', fieldName: 'Transaction_Reference_Number__c', type: 'text', sortable: true, },
        { label: 'EFT#', fieldName: 'EFT_Number__c', type: 'text', sortable: true, editable: true },
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
        return this.template.querySelector('c-funding-details-datatable');
    }

    handleSetEFTClick(event) {
        this.setEFT(this.eftNum)
        //this.dt.draftValues = this.draftValues;
    }

    @api setEFT(eftNum) {
        this.eftNum = eftNum;
        let _draftValues = [...this.dataTable.draftValues] || [];

        this.dataTable.selectedRows.forEach(id => {
            const idx = _draftValues.findIndex(record => {return record.Id === id});
            if (idx >= 0) {
                _draftValues[idx].EFT_Number__c = this.eftNum;
            } else {
                _draftValues.push({Id: id, EFT_Number__c: this.eftNum});
            }
        });
        this.draftValues = _draftValues;
    }

    handleEFTChange(event) {
        this.eftNum = event.detail.value;
    }

}