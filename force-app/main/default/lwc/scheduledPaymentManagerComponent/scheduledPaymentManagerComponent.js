import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

import getScheduledPayments from '@salesforce/apex/PaymentController.getScheduledPayments';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import deletePayment from '@salesforce/apex/ScheduledPaymentHelper.deletePayment';

const PERMISSION_CLASSES = [
    'Payment_Admin',
    'Can_Schedule_Payments',
    'Can_Process_Scheduled_Payments'
]

export default class ScheduledPaymentManagerComponent extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track loading = true;

    @api oppObj;
    @api oppId; // = "00619000007G46eAAC";

    @track columns;
    @track data;
    @track error;
    @track maxAmount;
    previousAmountAvailable; // Used to track if Opportunity has been updated

    @track boolTrue = true;
    @track boolFalse = false;

    @track showAdd = false;
    _shown = false;
    @api 
    get shown() {
        return this._shown;
    }
    set shown(value) {
        this._shown = !!value;
        this.setShowHideText();
    }
    @api toggleShown(value) {
        if (value !== undefined) {
            this.shown = value;
        } else {
            this.shown = !this.shown;
        }
        return this.shown;
    }
    /*
    get shown() {
        return this._shown
    }
    set shown(value) {
        this._shown = value;
    }
    */
    @track showHideText = "Show Scheduled Payments";
    @track showHideIcon = "utility:chevrondown";

    @track sortedBy = "Scheduled_Date__c";
    @track sortedDirection = 'asc'; 

    @track disabledCreateFields = ['Opportunity__c'];
    @track disabledEditFields = ['Opportunity__c'];
    @track selectedScheduledPaymentId;
    @track previousScheduledPaymentAmount;
    @track showCreateForm = false;
    @track showEditForm = false;

    permissions = {};

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
            this.showAdd = this.permissions.Can_Schedule_Payments;
        }
    }

    wiredResults;

    @wire(getScheduledPayments, { opportunityId: '$oppId' })
    imperativeWiring(result) {
        this.loading = false;
        this.wiredResults = result;
        if (result.data) {
            this.data = result.data;
            this.sortData(this.sortedBy, this.sortedDirection);
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    @api
    refresh() {
        if (this.oppId) {
            this.loading = true;
            this.syncMaxAmount();
            return refreshApex(this.wiredResults)
                .finally(() => { this.loading = false; }); 
        }
        return undefined
    }

    get shouldShowTable() {
        return this.data && this._shown;
    }

    get newButtonDisabled() {
        return !(this.maxAmount && this.maxAmount > 0);
    }

    constructor() {
        super();
        this.columns = [
            { label: 'Type', fieldName: 'Payment_Type__c', type: 'string', sortable: true },
            { label: 'Scheduled', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': "UTC"}, sortable: true },
            { label: 'Bank Account', fieldName: 'Current_Bank_Account_Name__c', type: 'string', sortable: true },
            { label: 'Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
            { label: 'Status', fieldName: 'Status__c', sortable: true },
            { label: 'Hold', fieldName: 'Hold__c', type: 'boolean', sortable: true },
            { label: 'Notes', fieldName: 'Notes__c', type: 'html', sortable: true },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ]
    }

    connectedCallback() {
        this.syncMaxAmount();
        registerListener(`scheduledpaymentschanged-${this.oppId}`, this.refresh, this);
        registerListener(`amountschanged-${this.oppId}`, this.syncMaxAmount, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    syncMaxAmount() {
        if (this.oppObj.Amount_Available_for_Scheduled_Payments__c !== this.previousAmountAvailable) {
            this.previousAmountAvailable = this.oppObj.Amount_Available_for_Scheduled_Payments__c
            this.maxAmount = this.oppObj.Amount_Available_for_Scheduled_Payments__c;
        }
    }

    handleShowHideClick(event) {
        this.shown = !this.shown;
        this.setShowHideText();
    }

    setShowHideText() {
        if (this.shown) {
            this.showHideText = 'Hide Scheduled Payments';
            this.showHideIcon = 'utility:chevronup';
        } else {
            this.showHideText = "Show Scheduled Payments";
            this.showHideIcon = "utility:chevrondown";
        }
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        fetchCustomPermissions({permissions: [
            'Payment_Admin',
            'Can_Schedule_Payments',
            'Can_Process_Scheduled_Payments'
        ]}).then(result => {
            if (result.Payment_Admin) {
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
                doneCallback(actions);
            } else if (row.Status__c === 'Scheduled' || row.Status__c === 'Rejected' || !row.Status__c || row.Hold__c) {
                if (result.Can_Schedule_Payments) {
                    if (row.Payment_Type__c === 'Scheduled Facility') {
                        actions.push({
                            label: 'Edit',
                            iconName: 'utility:edit',
                            name: 'edit_scheduled_facility'
                        });
                    } else {
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
                    }
                } else {
                    actions.push({
                        label: 'Can not be edited',
                        name: 'do_not_edit',
                        disabled: true
                    });
                }
                doneCallback(actions);
            } else {
                actions.push({
                    label: 'Can not be edited',
                    name: 'do_not_edit',
                    disabled: true
                });
                doneCallback(actions);
            }
        }, error => {
            actions.push({
                label: 'Can not be edited',
                name: 'do_not_edit',
                disabled: true
            });
            doneCallback(actions);
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.disabledEditFields = ['Opportunity__c'];
                this.selectedScheduledPaymentId = row.Id;
                this.previousScheduledPaymentAmount = row.Amount__c || 0;
                this.showEditModal();
                break;
            case 'edit_scheduled_facility':
                this.disabledEditFields = ['Opportunity__c', 'Amount__c']; //, 'Scheduled_Date__c'];
                this.selectedScheduledPaymentId = row.Id;
                this.previousScheduledPaymentAmount = row.Amount__c || 0;
                this.showEditModal();
                break;
            default:
        }
    }

    deleteRow(row, force) {
        this.loading = true;
        let forceDelete = !!force;
        deletePayment({
            spId: row.Id, 
            force: forceDelete
        })
            .then(() => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully removed payment from schedule',
                        variant: 'success'
                    })
                );
                this.maxAmount += row.Amount__c;
                this.fireScheduleChanged();
                if (row.Payment_Type__c === 'Payment to Other Lender') {
                    fireEvent(this.pageRef, `previousloanschanged-${this.oppId}`);
                } else if (row.Payment_Type__c === 'Treatment') {
                    this.fireInvoicesChanged();
                }
                return this.refresh();
            })
            .catch(error => {
                if (forceDelete) {
                    // already tried to override, so there must be a problem
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: reduceErrors(error).join(', '),
                            variant: 'error'
                        })
                    );
                }
                this.loading = false;
                let message = reduceErrors(error).join(', ') + '\n\nAre you sure you want to delete?';
                if (confirm(message)) {
                    this.deleteRow(row, true);
                }
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
        let _data = JSON.parse(JSON.stringify(this.data));
        //this.data.forEach(obj => _data.push({...obj}))

        switch(fieldName) {
            case 'Scheduled_Date__c':
                _data.sort((a, b) => reverse * (new Date(a[fieldName]) - new Date(b[fieldName])));
                break;
            default:
                _data.sort(function(a, b) {
                    if (a[fieldName] < b[fieldName]) {
                        return reverse * -1;
                    } else if (a[fieldName] > b[fieldName]) {
                        return reverse
                    }
                    return 0
                });
        }
        this.data = _data;
    }

    /* CREATE MODAL METHODS */
    handleCreateFormLoad(event) {
        // Set default values
        //this.template.querySelector('.Scheduled_Date__c').value = new Date().toLocaleDateString(); // Need for format date as d-MMM-yyyy
        if (this.maxAmount) {
            this.template.querySelector('.Amount__c').value = this.maxAmount;
        }
    }

    handleCreateSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Opportunity__c = this.oppId;
        this.template.querySelector("lightning-record-edit-form.createForm").submit(fields);
    }

    handleCreateSuccess(event) {
        this.maxAmount -= event.detail.fields.Amount__c.value;
        this.refresh();
        this.hideCreateModal();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully scheduled a new payment',
                variant: 'success'
            })
        );
        this.fireScheduleChanged();
    }

    @api showCreateModal() {
        if (this.permissions.Can_Schedule_Payments) {
            this.showCreateForm = true;
            const modal = this.template.querySelector("c-modal.createModal")
            modal.show();
        }
    }

    hideCreateModal() {
        this.showCreateForm = false;
        const modal = this.template.querySelector("c-modal.createModal")
        modal.hide();
    }
    /* END CREATE MODAL METHODS */

    /* EDIT MODAL METHODS */
    handleEditSuccess(event) {
        this.maxAmount += this.previousScheduledPaymentAmount - event.detail.fields.Amount__c.value;
        this.refresh();
        this.hideEditModal();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully updated the scheduled payment',
                variant: 'success'
            })
        );
        this.fireScheduleChanged();
        if (event.detail.fields.Payment_Type__c.value === 'Treatment') {
            this.fireInvoicesChanged();
        }
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

    fireInvoicesChanged() {
        const filterChangeEvent = new CustomEvent('invoiceschanged', {});
        // Fire the custom event
        this.dispatchEvent(filterChangeEvent);
    }

    fireScheduleChanged() {
        const filterChangeEvent = new CustomEvent('schedulechanged', {});
        // Fire the custom event
        this.dispatchEvent(filterChangeEvent);
    }
}