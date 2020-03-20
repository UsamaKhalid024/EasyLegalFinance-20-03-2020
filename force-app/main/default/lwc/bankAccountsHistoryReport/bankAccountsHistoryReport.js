import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getUsedBankAccounts from '@salesforce/apex/BankAccountsController.getUsedBankAccounts';

export default class BankAccountsHistoryReport extends LightningElement {
    @api recordId;
    @api accountId;

    @track loading = true;
    @track data;
    @track columns = [
        { label: 'Account', fieldName: 'accountId', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'accountName'}}, sortable: true },
        { label: 'Bank Account', fieldName: 'bankAccountId', type: 'bankAccount', typeAttributes: {target: '_blank', label: {fieldName: 'name'}, bankAccount: {fieldName: 'bankAccount'}}, sortable: true },
        { label: 'Scheduled Payments', fieldName: 'scheduledCount', type: 'number', sortable: true },
        { label: 'Scheduled Amount', fieldName: 'scheduledAmount', type: 'currency', sortable: true },
        { label: 'Sent Payments', fieldName: 'sentCount', type: 'number', sortable: true },
        { label: 'Sent Amount', fieldName: 'sentAmount', type: 'currency', sortable: true }
        // Need to add in actual bank account fields here
    ];

    @wire(getUsedBankAccounts, { accountId: '$accountId' })
    wiredGetUsedBankAccounts(result) {
        this.loading = false;
        this.wiredResults = result;
        if (result.data) {
            this.data = result.data;
            //this.sortData(this.sortedBy, this.sortedDirection);
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    @api
    refresh() {
        this.loading = true;
        return refreshApex(this.wiredResults)
            .finally(() => { this.loading = false; }); 
    }
}