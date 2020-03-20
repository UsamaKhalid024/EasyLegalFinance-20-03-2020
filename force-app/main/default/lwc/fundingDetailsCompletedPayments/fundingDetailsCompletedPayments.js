import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { loadGlobalCss, combineData } from 'c/fundingDetailsUtils';
import { showToast } from 'c/showToast';
import fuse from '@salesforce/resourceUrl/fuse';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';

export default class FundingDetailsCompletedPayments extends LightningElement {
    @track data;
    @track filteredList;
    @track spList;
    @track spMap;
    @track oppList;
    @track oppMap;
    @track errors;
    @track sortedBy = 'Verified_Date__c';
    @track sortedDirection = 'desc';
    @track selectedScheduledPaymentId;
    @track drawdownId;
    @track showReverseForm = false;

    _queryTerm = '';

    _queryTerm = '';
    @api 
    get queryTerm() {
        return this._queryTerm;
    }
    set queryTerm(value) {
        if (this.queryTerm != value && this.filterInitilized && this.resourcesInitialized) {
            this._queryTerm = value;
            this.performSearch();
        }
    }

    _filters = {
        preset: 'today'
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


    @track flattenedList;
    @track loading = true;

    @track columns = [
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        { label: 'File #', fieldName: 'opportunity.Account.AccountNumber', type: 'text', sortable: true },
        { label: 'Client', fieldName: '_client_account', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        //{ label: 'Payment Account', fieldName: 'Account__c', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        { label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        { label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c', type: 'text', sortable: true },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        //{ label: 'Send Cheque', fieldName: 'Send_Cheque__c', type: 'boolean', sortable: true },
        //{ label: 'Admin Fee', fieldName: 'Triggered_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        //{ label: 'Scheduled', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Sent to Bank', fieldName: 'Sent_to_Bank_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Drawdown Date', fieldName: 'Drawdown_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        //{ label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
        { label: 'Verified By', fieldName: 'Verified_By__r.Name', type: 'text', sortable: true },
        { label: 'Verified', fieldName: 'Verified_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
    ];

    getRowActions(row, doneCallback) {
        //console.log('Row ' + row.Id + ' '  + row.Can_Be_Reversed__c + '  ' + row.Drawdown__c);
        const actions = [];        
        {
            fetchCustomPermissions({permissions: [
                'Can_Process_Scheduled_Payments'
            ]}).then(result => {
                if (result.Can_Process_Scheduled_Payments) {
                    actions.push({
                        label: 'Reverse',
                        iconName: 'utility:edit',
                        name: 'reverse',
                        disabled: !row.Can_Be_Reversed__c
                    });
                }
                doneCallback(actions);
            });
        }
    }


    fuse;
    fuseOptions = {
        shouldSort: true,
        threshold: 0.3,
        //location: 0,
        distance: 100,
        maxPatternLength: 32,
        minMatchCharLength: 1,
        keys: [
            'opportunity.Account.AccountNumber',
            'opportunity.Account.Name',
            'Account__r.Name',
            'Verified_By__r.Name'
        ]
    };

    filterInitilized = true;
    resourcesInitialized = false;

    constructor() {
        super();
        this.addEventListener('search', this.performSearch.bind(this));
    }

    connectedCallback() {
        if (!this.resourcesInitialized) {
            this.loading = true;
            loadGlobalCss(this);
            Promise.all([
                loadScript(this, fuse + '/fuse.js')
            ])
                .then(() => {
                    this.resourcesInitialized = true;
                    if (this.filterInitilized) {
                        this.refresh();
                    }
                }).catch(error => {
                    showToast(
                        this,
                        'Error loading fuse',
                        error.message,
                        'error'
                    );
                })
        }
    }

    handleFilterInitialized(event) {
        this._filters = {...event.detail};
        this.filterInitilized = true;
        if (this.filterInitilized && this.resourcesInitialized) {
            this.refresh();
        }
    }

    @api refresh() {
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'reviewClosedPayments',
            dateField: 'Verified_Date__c'
        };
        // Add in lower bounds here if selected
        getScheduledPaymentsWithOpportunities(options)
            .then(result => {
                this.data = result;
                combineData(this.data)
                    .then(combinedData => {
                        this.spList = combinedData.spList;
                        this.filteredList = combinedData.spList;
                        this.oppMap = combinedData.oppMap;
                        this.spMap = combinedData.spMap;
                        this.loading = false;
                        this.error = undefined;
                        this.initFuse();
                        //this.flattenList();
                    });
            })
            .catch(error => {
                this.error = error;
                this.data = undefined;
                this.spList = undefined;
                this.filteredList = undefined;
                this.oppList = undefined;
                this.selectedScheduledPayment = undefined;
                this.selectedOpportunity = undefined;
            });
    }

    handleChangeFilterDate(event) {
        this._filters = {...event.detail};
        this.refresh();
        let evt = new CustomEvent('filterchange', {
            detail: {...this.filters}
        });
        this.dispatchEvent(evt);
    }

    handleSearchKeyup(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            window.clearTimeout(this.searchTimeout);
            this.queryTerm = evt.target.value;
            this.performSearch();
        }
    }

    handleSearchChange(evt) {
        window.clearTimeout(this.searchTimeout);
        this.queryTerm = evt.target.value;
        
        (function (_this) {
            _this.searchTimeout = setTimeout(() => {
                _this.dispatchEvent(new CustomEvent("search"));
            }, 300);
        })(this);
        
    }

    initFuse() {
        this.fuse = new Fuse(this.spList, this.fuseOptions);
        if (this.queryTerm) {
            this.performSearch();
        }
    }

    async performSearch() {
        if (this.queryTerm) {
            this.filteredList = this.fuse.search(this.queryTerm);
        } else {
            this.filteredList = this.spList;
        }
        //this.flattenList();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'reverse':
                //this.selectedScheduledPaymentId = row.Id;                
                this.drawdownId = row.Drawdown__c;
                this.showReverseModal();
                break;
            default:
        }
    }

    /* REVERSE MODAL METHODS */
    handleReverseSuccess(event) {
        this.refresh();
        this.hideReverseModal();

        showToast(
            this,
            'Success',
            'Successfully reversed the payment',
            'success'
        );
    }

    showReverseModal() {
        this.showReverseForm = true;
        const modal = this.template.querySelector("c-modal.reverseModal")
        modal.show();
    }

    hideReverseModal() {
        this.showReverseForm = false;
        const modal = this.template.querySelector("c-modal.reverseModal")
        modal.hide();
    }
    /* END REVERSE MODAL METHODS */
}
