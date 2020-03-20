import { LightningElement, api, track } from 'lwc';

export default class ReportGroup extends LightningElement {
    _group;
    @api 
    get group() {
        return this._group
    }
    set group(g) {
        let rowIdx = 0;
        this._group = {...g}
        this._group.fieldDataList = this._group.fieldDataList.map(row => {
            let cellIdx = 0;
            let newRow = {
                key: `${g.fieldLabel}-${rowIdx}`,
                cells: row.map(cell => {
                    let newCell = {...cell};
                    newCell.key = `${g.fieldLabel}-${rowIdx}-${cellIdx}`;
                    cellIdx += 1;
                    return newCell
                })
            }
            rowIdx += 1;
            return newRow
        })
    }
}