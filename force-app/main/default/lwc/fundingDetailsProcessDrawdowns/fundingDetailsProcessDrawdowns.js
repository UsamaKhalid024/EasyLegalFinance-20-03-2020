import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { showToast } from 'c/showToast';
import { deleteRecord } from 'lightning/uiRecordApi';
//import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';
//import getDrawdownsByOpp from '@salesforce/apex/FundingDetailsComponentCtlr.getDrawdownsByOpp';
import getDrawdowns from '@salesforce/apex/DrawdownHelper.getDrawdowns';
import generateDrawdowns from '@salesforce/apex/ScheduledPaymentHelper.generateDrawdowns';
import getScheduledPaymentsByOpp from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsByOpp';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

const FIELDS = [
    'Amount__c',
    'Date__c',
    'Payment_Method__c',
    'EFT__c',
    'CHQ__c',
    'Reference_Notes__c'
]

export default class FundingDetailsProcessDrawdowns extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track fields = FIELDS;
    @api opp; // = "00619000007G46eAAC";
    @api oppId; // = "00619000007G46eAAC";
    @api queryFields;
    @api customConditions;
    @api queryExtra;
    @api permissions;
    @api hideExtra = false;
    @api readOnly = false;
    @api title = "Drawdowns";
    @api iconName = "utility:money"

    @track ddLoading = false;
    @track spLoading = false;
    @track spDraftValues;

    @track spColumns = [
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        { label: 'Drawdown Created', fieldName: 'Drawdown_Created__c', type: 'boolean' },
        //{ label: 'Drawdown', fieldName: 'Drawdown__r.Name' },
        { label: 'Payment Account', fieldName: 'Current_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Account_Name__c'}} },
        { label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}} },
        { label: 'Payment Type', fieldName: 'Payment_Type__c' },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency' },
        { label: 'Previously Rejected', fieldName: 'Has_Been_Rejected__c', type: 'boolean' },
        { label: 'Drawdown Date', fieldName: 'Calculated_Drawdown_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'} },
        { label: 'Sent Date', fieldName: 'Sent_to_Bank_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'} },
        //{ label: 'Adming Fee', fieldName: 'Triggered_Admin_Fee_Amount__c', type: 'currency' },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency' },
    ];

    @track columns;
    @track data;
    @track error;

    @track showAdd = true;
    @track sortedBy = "Date__c";
    @track sortedDirection = 'asc'; 

    @track selectedId;
    @track showCreateForm = false;
    @track showEditForm = false;
    @track spList;

    get conditions() {
        if (this.customConditions) {
            return this.customConditions
        } else if (this.oppId) {
            return `Opportunity__c = '${this.oppId}'`
        }
        return null
    }

    @api
    refreshDrawdowns() {
        //return refreshApex(this.wiredResults); 
        this.ddLoading = true;
        let options = {
            fields: this.queryFields,
            conditions: this.conditions,
            extra: this.queryExtra
        };
        getDrawdowns(options)
            .then(result => {
                this.data = result;
                this.sortData(this.sortedBy, this.sortedDirection);
            })
            .catch(error => {
                showToast(
                    this,
                    'Error fetching drawdowns',
                    reduceErrors(error).join(', '),
                    'error'
                );
                this.data = undefined;
            })
            .finally(() => {
                this.ddLoading = false;
            });
    }

    @api
    refreshPayments() {
        //return refreshApex(this.wiredResults); 
        this.spLoading = true;
        getScheduledPaymentsByOpp({oppId: this.opp.Id, statuses: ['Processed by Bank', 'Drawdown Created']})
            .then(result => {
                this.spList = result;
                //this.sortData(this.sortedBy, this.sortedDirection);
            })
            .catch(error => {
                showToast(
                    this,
                    'Error fetching scheduled payments',
                    reduceErrors(error).join(', '),
                    'error'
                );
                this.data = undefined;
            })
            .finally(() => {
                this.spLoading = false;
            });
    }

    constructor() {
        super();
        this.columns = [
            { label: 'Drawdown', fieldName: 'Name', sortable: true },
            { label: 'Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
            { label: 'Date', fieldName: 'Date__c', type: 'date-local', typeAttributes: {'time-zone': "UTC"}, sortable: true },
            //{ label: 'Accrued Interest', fieldName: 'Total_Accrued_Interest__c', type: 'currency', sortable: true },
            { label: 'Payment Method', fieldName: 'Payment_Method__c', sortable: true },
            { label: 'EFT #', fieldName: 'EFT__c', sortable: true },
            { label: 'Chq #', fieldName: 'CHQ__c', sortable: true },
            { label: 'Reference Notes', fieldName: 'Reference_Notes__c', sortable: true },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ]
    }

    connectedCallback() {
        this.fireStopLoadingEvent();
        if (this.opp) {
            this.oppId = this.opp.Id;
            registerListener(`drawdownschanged-${this.oppId}`, this.refreshDrawdowns, this);
        }
        if ( this.readOnly ) {
            this.showAdd = false;
        }
        this.refreshDrawdowns();
        if (!this.hideExtra) {
            this.refreshPayments();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    fireStartLoadingEvent() {
        fireEvent(this.pageRef, 'startloading');
    }

    fireStopLoadingEvent() {
        fireEvent(this.pageRef, 'stoploading');
    }


    generateDrawdowns() {
        this.spLoading = true;
        const spIds = this.opp.Scheduled_Payments__r.map(sp => sp.Id);
        generateDrawdowns({spIds: spIds})
            .then(result => {
                //this.opp = {...this.opp};
                //this.opp.Scheduled_Payments__r = [...this.opp.Scheduled_Payments__r];
                /*
                this.spDraftValues = this.spList.map(sp => {
                    return {
                        Id: sp.Id,
                        Drawdown_Created__c: true
                    }
                });
                this.opp.Scheduled_Payments__r.forEach(sp => {
                    sp.Drawdown_Created__c = true
                });
                */

                showToast(
                    this,
                    'Drawdowns Successfully Created',
                    '',
                    'success'
                );
                this.refreshDrawdowns();
                this.refreshPayments();
            })
            .catch(error => {
                showToast(
                    this,
                    'Error deleting record',
                    reduceErrors(error).join(', '),
                    'error'
                );
            })
            .finally(() => {
                this.spLoading = false;
            });
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        //if (this.permissions.Can_Schedule_Payments) {
            actions.push({
                label: 'Edit',
                iconName: 'utility:edit',
                name: 'edit'
            });
            actions.push({
                label: 'Delete',
                iconName: 'utility:delete',
                name: 'delete'
            });
        /*
        } else {
            actions.push({
                label: 'Can not be edited',
                name: 'do_not_edit',
                disabled: true
            });
        }
        */
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.selectedId = row.Id;
                this.showEditModal();
                break;
            default:
        }
    }

    deleteRow(row) {
        this.ddLoading = true;
        deleteRecord(row.Id)
            .then(() => {
                showToast(
                    this,
                    'Success',
                    'Successfully deleted drawdown',
                    'success'
                );
                if (!this.hideExtra) {
                    this.refreshPayments();
                }
                this.fireDrawdownsChanged();
                return this.refreshDrawdowns();
            })
            .catch(error => {
                this.ddLoading = false;
                showToast(
                    this,
                    'Error deleting record',
                    reduceErrors(error).join(', '),
                    'error'
                );
            });
    }

    updateColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {
        const reverse = sortDirection === 'asc' ? 1 : -1;

        // Make copy of data as wired data is immutable
        let _data = [...this.data];
        //this.data.forEach(obj => _data.push({...obj}))

        switch(fieldName) {
            case 'Date__c':
                _data.sort((a, b) => {
                    let diff = reverse * (new Date(a[fieldName]) - new Date(b[fieldName]));
                    if (diff !== 0) {
                        return diff
                    } else if (a.Name < b.Name) {
                        return reverse * -1;
                    } else if (a.Name > b.Name) {
                        return reverse;
                    }
                    return 0
                });
                break;
            default:
                _data.sort(function(a, b) {
                    if (a[fieldName] < b[fieldName]) {
                        return reverse * -1;
                    } else if (a[fieldName] > b[fieldName]) {
                        return reverse
                    } else if (a.Name < b.Name) {
                        return reverse * -1;
                    } else if (a.Name > b.Name) {
                        return reverse;
                    }
                    return 0
                });
        }
        this.data = _data;
    }

    /* CREATE MODAL METHODS */

    handleCreateSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Opportunity__c = this.opp.Id;
        this.template.querySelector("lightning-record-form.createForm").submit(fields);
    }

    handleCreateSuccess(event) {
        this.refreshDrawdowns();
        this.hideCreateModal();
        showToast(
            this,
            'Success',
            'Successfully created drawdown',
            'success'
        );
        this.fireDrawdownsChanged();
    }

    showCreateModal() {
        this.showCreateForm = true;
        const modal = this.template.querySelector("c-modal.createModal")
        modal.show();
    }

    hideCreateModal() {
        this.showCreateForm = false;
        const modal = this.template.querySelector("c-modal.createModal")
        modal.hide();
    }
    /* END CREATE MODAL METHODS */

    /* EDIT MODAL METHODS */
    handleEditSuccess(event) {
        this.refreshDrawdowns();
        this.hideEditModal();
        showToast(
            this,
            'Success',
            'Successfully updated the drawdown',
            'success'
        );
        this.fireDrawdownsChanged();
    }

    fireDrawdownsChanged() {
        const filterChangeEvent = new CustomEvent('drawdownschanged', {});
        this.dispatchEvent(filterChangeEvent);
    }

    showEditModal() {
        this.showEditForm = true;
        const modal = this.template.querySelector("c-modal.editModal")
        modal.show();
    }

    hideEditModal() {
        this.showEditForm = false;
        const modal = this.template.querySelector("c-modal.editModal")
        modal.hide();
    }
    /* END EDIT MODAL METHODS */

    fireStageComplete() {
        this.fireStartLoadingEvent();
        const evt = new CustomEvent("markstagecomplete");
        this.dispatchEvent(evt);
    }

}