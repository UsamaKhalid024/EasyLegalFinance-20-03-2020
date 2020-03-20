import LightningDatatable from 'lightning/datatable';
import address from './address.html';
import linkWithLabel from './linkWithLabel.html';
import textInput from './textInput.html';
import helptext from './helptext.html';
import html from './html.html';
import linkToId from './linkToId.html';
import bankAccount from './bankAccount.html';
import checkbox from './checkbox.html';

export default class FundingDetailsDatatable extends LightningDatatable {
    static customTypes = {
       address: {
           template: address 
       },
       bankAccount: {
           template: bankAccount,
           typeAttributes: [
                'label',
                'target',
                'tooltip',
                'bankAccount'
            ],
       },
       checkbox: {
           template: checkbox,
           typeAttributes: [
                'label'
           ]
       },
       helptext: {
           template: helptext
       },
       html: {
           template: html
       },
       linkToId: {
           template: linkToId,
           typeAttributes: [
                'label',
                'target',
                'tooltip'
            ],
       },
       linkWithLabel: {
           // Expects an object with url and label attributes as the value
           template: linkWithLabel,
           // Provide template data here if needed
           typeAttributes: [
                'target',
                'tooltip'
            ],
       },
       textInput: {
           template: textInput
       }
   }
}