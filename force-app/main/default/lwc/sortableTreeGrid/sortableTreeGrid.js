import LightningTreeGrid from 'lightning/treeGrid';
import LightningDatatable from 'lightning/datatable';

export default class SortableTreeGrid extends LightningTreeGrid {//LightningDatatable{}
    connectedCallback() {
        console.log('connected');
    }

    renderedCallback() {
        console.log('rendered');
    }
}