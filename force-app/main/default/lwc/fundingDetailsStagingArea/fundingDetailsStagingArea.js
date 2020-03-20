import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { loadGlobalCss, combineData } from 'c/fundingDetailsUtils';
import { showToast } from 'c/showToast';
import fuse from '@salesforce/resourceUrl/fuse';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
import updateScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.updateScheduledPayments';

export default class FundingDetailsStagingArea extends LightningElement {
    _filters = {
        preset: 'this_week'
    }
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value || this._filters;
        //this.refresh();
        if (this.filterInitilized && this.resourcesInitialized) {
            this.refresh();
        }
    }

    @track groupedPayments;
    @track data;
    @track filteredList;
    @track spList;
    @track spMap;
    @track oppList;
    @track oppMap;
    @track errors;
    @track sortedBy = 'Scheduled_Date__c';
    @track sortedDirection = 'asc';

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

    @track flattenedList;
    @track loading = true;

    @track columns = [
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        { label: 'File #', fieldName: 'opportunity.Account.AccountNumber', type: 'text', sortable: true },
        { label: 'Client', fieldName: '_client_account', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        { label: 'Payment Account', fieldName: 'Account__c', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        { label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        { label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c', type: 'text' },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        { label: 'Send Cheque', fieldName: 'Send_Cheque__c', type: 'boolean', sortable: true },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
    ];

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

    @api refresh() {
        this.loading = true;
        //const dates = this.querySelector('c-date-range-picker').getDates();
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'staging',
            //dateField: 'Sent_to_Bank_Date__c'
        };
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
                        /*
                        groupPayments(this.spList, 'Opportunity__c')
                            .then(groupedPayments => {
                                this.groupedPayments = groupedPayments;
                                this.loading = false;
                            })
                        */
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
            })
            .finally(() => {
                this.loading = false;
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

    stageSelected() {
        const updateObjects = this.datatable.selectedRows.map(rowId => {
            return {
                'sobjectType': 'Scheduled_Payment__c',
                'Id': rowId,
                'Status__c': 'Pre Send Validation'
            }
        });
        if (updateObjects.length) {
            this.loading = true;
            updateScheduledPayments({scheduledPayments: updateObjects})
                .then(result => {
                    showToast(this, 
                        'Successfully Staged Payments',
                        'The payments have been marked as Staged, and can be further processed now.',
                        'success',
                    );

                    // call for refresh of data
                    //sendNeedsRefreshEvent(this);
                    this.refresh();
                    this.loading = false;
                })
                .catch(error => {
                    this.loading = false;
                    showToast(this, 
                        'There was an error',
                        JSON.stringify(error),
                        'error',
                        'sticky'
                    );
                });
        }
        // Loop over selected
        // Create object with Id
        // Set status to "Pre Send Validation"
        // call updateScheduledPayments()
        //let newObj = {'sobjectType': 'Scheduled_Payment__c', 'Id': draftValue.Id};
    }

    get datatable() {
        return this.template.querySelector('c-funding-details-datatable-wrapper');
    }

    async performSearch() {
        if (this.queryTerm) {
            this.filteredList = this.fuse.search(this.queryTerm);
        } else {
            this.filteredList = this.spList;
        }
        //this.flattenList();
    }
}