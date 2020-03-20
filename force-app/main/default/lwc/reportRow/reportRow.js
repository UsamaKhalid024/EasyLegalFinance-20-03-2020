import { LightningElement, api } from 'lwc';

export default class ReportRow extends LightningElement {
    _row;
    @api 
    get row() {
        return this._row
    }
    set row(value) {
        let idx = 0;
        this._row = value.map(cell => {
            let newCell = {...cell};
            newCell.key = idx;
            idx += 1;
            return newCell
        })
    }
    @api isHeader = false;
}