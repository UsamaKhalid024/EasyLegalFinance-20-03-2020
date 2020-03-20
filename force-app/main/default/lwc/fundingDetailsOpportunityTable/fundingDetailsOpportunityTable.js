import { LightningElement, api, track, wire } from 'lwc';
//import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import getOpportunitiesWithScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments';
import { flatten } from 'c/flatley';

export default class FundingDetailsOpportunityTable extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @track _oppList = [];
    @api
    get oppList(){
        return this._oppList;
    }
    set oppList(value){
        this._oppList = value || [];
        this.buildNestedData();
    }


    _filters = {};
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value || this._filters;
        this.refresh();
    }



    @api refresh() {
        this.refreshData();
    }

    @api permissions;

    @track data;
    @track selectedOpp;
    @track currentExpanded;
    @track selectedRows = [];
    @track columns = [
        { label: '', type: 'button-icon', initialWidth: 20, typeAttributes:
            { title: 'Select', name: 'select', iconName: 'action:check', class: 'slds-hide' } }, // Empty row to handle graphical issues with chevron
        {label: 'Select', type: 'button', initialWidth: 100, typeAttributes:
            { label: 'Select', title: 'Select', name: 'select_row',
                class: {fieldName: 'showButton'}, variant: 'brand'} },
        { label: 'Stage', fieldName: 'stage', initialWidth: 160 },
        { label: 'File #', fieldName: 'file', initialWidth: 100 },
        { label: 'Name', fieldName: 'accountUrl', type: 'url', typeAttributes: { label: { fieldName: 'name'}, target: '_blank'} },
        { label: 'Loan Amount', fieldName: 'loanAmount', type: 'currency', initialWidth: 140 },
        { label: 'Admin Fee', fieldName: 'adminFee', type: 'currency', initialWidth: 120 },
        { label: 'Paid Date', fieldName: 'paymentDate', type: 'date-local', initialWidth: 120 },
        { label: 'Payment Type', fieldName: 'paymentType', initialWidth: 160 },
        { label: 'Payment Amount', fieldName: 'paymentAmount', type: 'currency', initialWidth: 160 },
    ];

    refreshData() {
        this.fetchOpporunities()
            .then(() => {
                this.refreshNestedData();
                this.loading = false;
            })
            .catch(() => {
                this.loading = false;
            })
    }

    fetchOpporunities() {
        return new Promise((resolve, reject) => {
            this.loading = true;
            // Add Date Filter
            getOpportunitiesWithScheduledPayments({
                startDate: this.filters.startDate,
                endDate: this.filters.endDate
            })
                .then(result => {
                    result.forEach(opp => {
                        opp.Scheduled_Payments__r = opp.Scheduled_Payments__r || [];
                        /*
                        if (opp.Scheduled_Payments__r) {
                            opp.Scheduled_Payments__r = opp.Scheduled_Payments__r.map(sp => {
                                return flatten(sp)
                            });
                        } else {
                            opp.Scheduled_Payments__r = [];
                        }
                        */
                    });
                    this._oppList = result;
                    this.data = result;
                    this.loading = false;
                    this.error = undefined;
                    resolve(this.oppList);
                })
                .catch(error => {
                    this.error = error;
                    this.data = undefined;
                    this._oppList = undefined;
                    this.selectedOpportunity = undefined;
                    reject(error);
                });
        })
    }

    refreshNestedData() {
        this.buildNestedData()
            .then(() => {
                this.refreshEditComponent();
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
            });
    }

    /*
    // Tree Grid does not support sorting, and Shadow Dom prevents meddling with underlying table...
    // Perhaps I should just have a drop down or stop using the tree-grid...
    @track sortedBy = 'stage';
    @track sortedDirection = 'asc';
    renderedCalled = false;
    renderedCallback() {
        if (!this.renderedCalled) {
            this.renderedCalled = true;
            // bind column sorting to table in tree grid
            const table = this.template.querySelector('lightning-data-table');
            .
            table.sortedBy = this.sortedBy;
            table.sortedDirection = this.sortedDirection;
            table.onsort = this.updateColumnSorting;
        }
    }

    updateColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
    }
    */

    buildNestedData() {
        return new Promise(resolve => {
            this.data = [];
            this.oppList.forEach(opp => {
                let newOpp = {
                    Id: opp.Id,
                    showButton: 'slds-show',
                    stage: opp.Funding_Details_Status__c,
                    file: opp.Account.AccountNumber,
                    accountUrl: `/lightning/r/Account/${opp.Account.Id}/view`,
                    name: `${opp.Account.Name} - ${opp.Loan_Requests__c}`,
                    loanAmount: opp.Amount,
                    adminFee: opp.Admin_Fee__c,
                    paymentDate: undefined,
                    paymentType: undefined,
                    paymentAmount: 0,
                    _children: []
                };
                if (opp.Scheduled_Payments__r) {
                    opp.Scheduled_Payments__r.forEach(sp => {
                        let newSp = {
                            Id: `${opp.Id}-${sp.Id}`,
                            showButton: 'slds-hide',
                            stage: sp.Status__c,
                            file: undefined,
                            accountUrl: `/lightning/r/Account/${opp.Account.Id}/view`,
                            name: `Payment to ${opp.Account.Name}`,
                            loanAmount: undefined,
                            adminFee: sp.Triggered_Admin_Fee_Amount__c, //sp.Expected_Admin_Fee_Amount__c,
                            paymentDate: sp.Sent_to_Bank_Date__c,
                            paymentType: sp.Payment_Type__c,
                            paymentAmount: sp.Amount__c
                        };
                        newOpp.paymentAmount += sp.Amount__c;
                        if (sp.Account__r) {
                            newSp.accountUrl = `/lightning/r/Account/${sp.Account__r.Id}/view`;
                            newSp.name = `Payment to ${sp.Account__r.Name}`;
                        }
                        newOpp._children.push(newSp);
                    })
                }
                this.data.push(newOpp);
            });
            this.data.sort((a, b) => {
                var nameA = a.name.toUpperCase(); // ignore upper and lowercase
                var nameB = b.name.toUpperCase(); // ignore upper and lowercase
                if (nameA < nameB) {
                    return -1;
                }
                if (nameA > nameB) {
                    return 1;
                }

                // names must be equal
                if (a.file < b.file) {
                    return -1;
                }
                if (a.file > b.file) {
                    return 1;
                }
                return 0;
            });
            resolve(this.data);
        })
    }

    handleRowAction(event) {
        let oppIndex = this.oppList.findIndex(record => {return record.Id === event.detail.row.Id})
        this.selectRow(oppIndex);
    }

    selectRow(oppIndex) {
        this.selectedOpp = this.oppList[oppIndex];
        this.selectedRows = [this.selectedOpp.Id];
        this.currentExpanded = [this.selectedOpp.Id];
    }

    connectedCallback() {
        //registerListener('opportunitiesChanged', this.refresh, this);
        this.refreshData();
    }

    disconnectedCallback() {
        //unregisterAllListeners(this);
    }

    refreshEditComponent() {
        if (this.selectedOpp) {
            let oppIndex = this.oppList.findIndex(record => {return record.Id === this.selectedOpp.Id})
            if (!(oppIndex >= 0)) {
                this.selectedOpp = undefined;
                this.selectedRows = [];
                if (this.oppList.length) {
                    this.selectRow(0);
                }
            }
            let editComp = this.template.querySelector('c-funding-details-opportunity-edit');
            if (editComp) {
                editComp.refresh();
            }
            //fireEvent(this.pageRef, 'opportunityChanged', this.selectedOpp)
        }
    }

    handleOpportunityChanged(event) {
        event.stopPropagation();
        let updatedOpp = event.detail;
        if (updatedOpp && updatedOpp.Id) {
            let oppListIdx = this.oppList.findIndex(record => {return record.Id === updatedOpp.Id});
            let currentOpp = this.oppList[oppListIdx]
            for (const key in updatedOpp) {
                if (key !== 'Id' && updatedOpp.hasOwnProperty(key)) {
                    // this.oppList[oppListIdx] = opp[key];
                    currentOpp[key] = updatedOpp[key];
                }
            }
            this.refreshNestedData();
        }
    }

    handleOpportunityRemoved(event) {
        event.stopPropagation();
        let removedOpp = event.detail;
        if (removedOpp && removedOpp.Id) {
            let oppListIdx = this.oppList.findIndex(record => {return record.Id === removedOpp.Id});
            // Actually remove oppo from list
            this.oppList.splice(oppListIdx, 1);
            this.refreshNestedData();
        }
    }
}
/*
Table to view and select an individual Opp to process
Should display opp information and Scheduled Payments that still need to be processed
    Aggregate information?
Should have scheduled and Sent to Bank filtered out
Should fire an Event to the parent when an Opp is selected
Can update status?


Opp Row (Stage stored on Opp)
    Child Payments
    When Opp is fully processed mark all payments as closed
*/