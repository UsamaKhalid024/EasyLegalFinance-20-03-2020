import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';

import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import { fireEvent } from 'c/pubsub';

const PERMISSION_CLASSES = [
    'Can_Schedule_Payments',
    'Can_Process_Scheduled_Payments'
]

export default class TreatmentInvoiceManager extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    _osp;
    @api oppServiceProvider
    get oppServiceProvider() {
        return this._osp
    }
    set oppServiceProvider(value) {
        this._osp = value;
    }
    @api invoices;

    //@api oppObj;
    //@api oppId = "00656000006fssnAAA";

    @track columns;
    @track error;

    @track boolTrue = true;
    @track boolFalse = false;

    @track selectedInvoice; // Used to pass information to different forms
    @track previousInvoiceAmount;
    @track showCreateForm = false;
    @track showEditForm = false;
    @track showScheduleForm = false;
    @track loading = false;
    @track showAdd = false;

    permissions = {};

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
            this.showAdd = this.permissions.Can_Schedule_Payments;
        }
    }

    get shouldShowTable() {
        return this.invoices;
    }

    connectedCallback() {
        console.dir(arguments);
    }

    constructor() {
        super();
        this.columns = [
            { label: 'Invoice', fieldName: 'Name', sortable: true },
            { label: 'Invoice Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
            { label: 'Date Received', fieldName: 'Date_Received__c', type: 'date-local', typeAttributes: {'time-zone': "UTC"}, sortable: true },
            { label: 'Invoice Number', fieldName: 'Provider_Invoice_Number__c', sortable: true },
            { label: 'Payment Requested', fieldName: 'Payment_Requested__c', type: 'currency', sortable: true },
            { label: 'Payment Status', fieldName: 'Status__c', sortable: true },
            { label: 'Paid', fieldName: 'Paid__c', type: 'Boolean', sortable: true },
            { label: 'Paid Date', fieldName: 'Paid_Date__c', type: 'date-local', typeAttributes: {'time-zone': "UTC"}, sortable: true },
            { label: 'Payment Amount', fieldName: 'Amount_Paid__c', type: 'currency', sortable: true },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ]
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        if (row.Status__c === 'Closed') {
            actions.push({
                label: 'Can not be edited',
                name: 'do_not_edit',
                disabled: true
            });
            doneCallback(actions);
        } else {
            // Don't have access to "this" in this context, so make a callout each time...
            fetchCustomPermissions({permissions: [
                'Can_Schedule_Payments'
            ]}).then(result => {
                if (result.Can_Schedule_Payments) {
                    if (row.Status__c === 'Ready to Schedule') {
                        actions.push({
                            label: 'Schedule Payout',
                            iconName: 'action:new_event',
                            name: 'schedule_payout'
                        });
                    } else if (row.Status__c === 'Scheduled') {
                        actions.push({
                            label: 'Edit Scheduled Payout',
                            iconName: 'action:new_event',
                            name: 'schedule_payout'
                        });
                    } 
                    actions.push({
                        label: 'Edit',
                        iconName: 'utility:edit',
                        name: 'edit'
                    });
                    if (row.Status__c === 'Ready to Schedule') {
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
            }, error => {
                actions.push({
                    label: 'Can not be edited',
                    name: 'do_not_edit',
                    disabled: true
                });
                doneCallback(actions);
            });
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.selectedInvoice = row;
                this.showEditModal();
                break;
            case 'schedule_payout':
                this.selectedInvoice = row;
                this.showScheduleModal();
                break;
            default:
        }
    }

    deleteRow(row) {
        this.loading = true;
        deleteRecord(row.Id)
            .then(() => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully deleted previous loan',
                        variant: 'success'
                    })
                );
                this.fireInvoicesChanged();
            })
            .catch(error => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    })
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
        let _data = JSON.parse(JSON.stringify(this.invoices));
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
        this.invoices = _data;
    }

    /* CREATE MODAL METHODS */

    handleCreateSuccess(event) {
        this.hideCreateModal();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully created a new previous loan',
                variant: 'success'
            })
        );
        this.fireInvoicesChanged();
    }

    @api showCreateModal() {
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
        this.hideEditModal();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully updated the previous loan',
                variant: 'success'
            })
        );
        this.fireInvoicesChanged();
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

    /* SCHEDULE MODAL METHODS */
    handleScheduleSuccess(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        fireEvent(this.pageRef, `scheduledpaymentschanged-${this.oppServiceProvider.Opportunity__c}`)
        updateRecord({
            fields: {
                Id: this.selectedInvoice.Id,
                Scheduled_Payment__c: event.detail.id
            }
        })
            .then(result => {
                this.fireInvoicesChanged();
                this.hideScheduleModal();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully updated the scheduled payout',
                        variant: 'success'
                    })
                )
            }).catch(error => {
                this.hideScheduleModal();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `There was a problem updating the invoice with the new Scheduled Payment's information:\n${JSON.stringify(error)}`,
                        variant: 'success'
                    })
                );
            });
    }

    showScheduleModal() {
        this.showScheduleForm = true;
        const modal = this.template.querySelector("c-modal.scheduleModal")
        modal.show();
    }

    hideScheduleModal() {
        this.showScheduleForm = false;
        const modal = this.template.querySelector("c-modal.scheduleModal")
        modal.hide();
    }
    /* END SCHEDULE MODAL METHODS */

    fireInvoicesChanged() {
        const filterChangeEvent = new CustomEvent('invoiceschanged', {});
        // Fire the custom event
        this.dispatchEvent(filterChangeEvent);
    }
}