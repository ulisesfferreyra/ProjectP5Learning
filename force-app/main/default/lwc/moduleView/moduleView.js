import { LightningElement, api } from 'lwc';

export default class ModuleView extends LightningElement {
    @api recordId;
    @api 
    module
    @api 
    thisUnits
    //parsedModule = JSON.parse(JSON.stringify(this.module));
    // parsedUnit = JSON.parse(JSON.stringify(this.thisUnits));

    @api
    get unitsFromModule(){
        return this.parsedUnit;
    }

    set unitsFromModule(value){
       let filteredUnits;
       for(let unit in value){
            if(unit.Module__c == this.parsedModule.Id){
                filteredUnits.push(unit);
            }
        }
        this.parsedUnit = filteredUnits;
    }
    
    handleClick(){
        console.log('MODULE');
        console.log(JSON.parse(JSON.stringify(this.module)));
        console.log('UNITS');
        console.log(JSON.parse(JSON.stringify(this.thisUnits)));
        console.log('FILTERED UNITS');
        console.log(parsedUnit)
    }

    handleClock(){
        console.log(JSON.parse(JSON.stringify(this.thisUnits)));
        
    }
}