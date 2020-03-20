import { LightningElement, api, track, wire } from 'lwc';

import {
    loadGlobalCss,
    PERMISSION_CLASSES,
    combineData,
    groupPayments
} from 'c/fundingDetailsUtils';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';

export default class FundingDetailsValidateEfts extends LightningElement {
    _filters = {
        preset: 'this_week'
    }
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value || this._filters;
        if (this.filterInitilized && this.resourcesInitialized) {
            this.refresh();
        }
    }

    @api paymentType = 'eft';

    get isCheque() {
        return this.paymentType === 'cheque'
    }

    /*
    @track groupingField = 'Opportunity__c'; // Default to Opportunity
    @track groupingFieldChoices = [
        {value: 'Current_Bank_Account_Name__c', label: 'Bank Account'},
        {value: 'Opportunity__c', label: 'Opportunity'},
    ]

    groupingFieldChange() {
        this.loading = true;
        groupPayments(this.spList, this.groupingField)
            .then(groupedPayments => {
                this.groupedPayments = groupedPayments;
                this.loading = false;
            })
    }
    */

    @track groupedPayments;
    @track data;
    @track spList;
    @track spMap;
    @track oppList;
    @track oppMap;
    @track selectedScheduledPayment;
    @track selectedOpportunity;
    @track permissions;
    @track pageSize = 50;

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }

    @track flattenedList;
    @track loading = true;
    confirmed = false
    @track bankingSheetText = 'I confirm that this data is accurate';

    /*
    @track columns = [
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        //{ label: 'File #', fieldName: 'opportunity.Account.AccountNumber', type: 'text', sortable: true },
        //{ label: 'Client Account', fieldName: 'client_account_url', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.Name'}}, sortable: true },
        { label: 'Payment Account', fieldName: 'Current_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Account_Name__c'}}, sortable: true },
        { label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        //{ label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c' },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        //{ label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        //{ label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
        { label: 'Bank Valid', fieldName: '_bankingValid', type: 'checkbox', typeAttributes: {label: 'Bank'} },
        { label: 'Credit Available', fieldName: '_creditValid', type: 'checkbox', typeAttributes: {label: 'Credit'} },
        { label: 'Documents Valid', fieldName: '_documentsValid', type: 'checkbox', typeAttributes: {label: 'Docs'} },
        { label: 'BIA/PPSA/LL Checked', fieldName: '_ppsaValid', type: 'checkbox', typeAttributes: {label: 'BIA/PPSA/LL'} },
    ];
    @track errors;
    @track sortedBy = 'Scheduled_Date__c';
    @track sortedDirection = 'asc';
    */

    filterInitilized = true;
    resourcesInitialized = false;
    dt; // dataTable reference

    connectedCallback() {
        if (!this.resourcesInitialized) {
            this.loading = true;
            loadGlobalCss(this);
            this.resourcesInitialized = true;
            if (this.filterInitilized) {
                this.refresh();
            }
        }
    }

    @api refresh() {
        this.loading = true;
        //this.selectedAll = false; // Seems to be bugging out, maybe a bug in LWC rendering?
        //this.selectAllText = 'Select All';
        //const dates = this.querySelector('c-date-range-picker').getDates();
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: this.isCheque ? 'validateCheque' : 'validateEft',
            //dateField: 'Sent_to_Bank_Date__c'
        };
        getScheduledPaymentsWithOpportunities(options)
            .then(result => {
                this.data = result;
                combineData(this.data)
                    .then(combinedData => {
                        this.spList = combinedData.spList;
                        this.oppMap = combinedData.oppMap;
                        this.spMap = combinedData.spMap;
                        this.loading = false;
                        this.error = undefined;
                        groupPayments(this.spList, 'Opportunity__c', true)
                            .then(groupedPayments => {
                                this.groupedPayments = groupedPayments;
                                this.loading = false;
                            })
                    });
            })
            .catch(error => {
                this.loading = false;
                this.error = error;
                this.data = undefined;
                this.spList = undefined;
                this.oppList = undefined;
                this.selectedScheduledPayment = undefined;
                this.selectedOpportunity = undefined;
            });
    }

    handleFilterInitialized(event) {
        this._filters = {...event.detail};
        this.filterInitilized = true;
        if (this.resourcesInitialized) {
            this.refresh();
        }
    }

    handleChangeFilterDate(event) {
        this._filters = {...event.detail};
        this.refresh();
        let evt = new CustomEvent('filterchange', {
            detail: {...this.filters}
        });
        this.dispatchEvent(evt);
    }

    /*
    get datatables() {
        return this.template.querySelectorAll('lightning-datatable');
    }

    @track selectedAll = false;
    @track selectAllText = "Select All"
    toggleSelectAll() {
        const dts = this.datatables;
        this.selectedAll = !this.selectedAll;
        if (this.selectedAll) {
            this.selectAllText = 'Unselect All';
            dts.forEach(dt => {
                dt.selectedRows = dt.data.map(row => row.Id);
            });
        } else {
            this.selectAllText = 'Select All';
            dts.forEach(dt => {
                dt.selectedRows = [];
            });
        }
    }

    getSelectedIds() {
        let spIds = [];
        this.datatables.forEach(dt => {
            spIds = spIds.concat(dt.selectedRows);
        });
        return spIds
    }
    */

}