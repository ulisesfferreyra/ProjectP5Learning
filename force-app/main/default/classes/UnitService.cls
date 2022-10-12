public with sharing class UnitService {
	
    @AuraEnabled
    public static void metodo(Id unitId){
        
        Id userId = UserInfo.getUserId();

        Unit__c unitQuery = [SELECT Id, Points__c, (SELECT Id FROM Units_Progress__r WHERE User__c=:userId) FROM Unit__c WHERE Id = :unitId LIMIT 1]; //WITH SECURITY_ENFORCED
        Unit_Progress__c unitP = null;
        for(Unit_Progress__c unitProgress: unitQuery.Units_Progress__r){
			unitP = unitProgress;
        }
        
        if(unitP == null){
            Unit__c unitIdQuery = [SELECT Module__c FROM Unit__c WHERE Id = :unitId];
            Module__c checkModule = [SELECT Skills__c, (SELECT Id FROM Modules_Progress__r WHERE User__c = :userId) FROM Module__c WHERE Id = :unitIdQuery.Module__c];


            if(checkModule.Modules_Progress__r.size() == 0){
            Module_Progress__c moduleProgressToInsert = new Module_Progress__c(Module__c = unitIdQuery.Module__c, User__c = userId,
            Status__c = 'In Progress', Skills__c = checkModule.Skills__c);
            insert moduleProgressToInsert;
        
        }

             Module__c moduleId = [SELECT Id, (SELECT Trail__c FROM Trails_Modules__r), (SELECT Name, Id FROM Units__r WHERE Id = :unitId), (SELECT Name, Id FROM Modules_Progress__r WHERE User__c = :userId) FROM Module__c WHERE Id IN (SELECT Module__c FROM Unit__c WHERE Id = :unitId)];
            
            Map<Id, Id> moduleProgressByUnit = new Map<Id, Id>();
            Id key;
            Id value;
            for(Unit__c unit: moduleId.Units__r){
                if(!moduleProgressByUnit.containsKey(unit.Id)){
                    key = unit.Id;
                }
            }
            for(Module_Progress__c moduleProgress: moduleId.Modules_Progress__r){
                value = moduleProgress.Id;
            }
            moduleProgressByUnit.put(key, value);
            
            if(moduleId.Trails_Modules__r != null){
                Id trailModuleId;
                Map<Id, Id> trailByTrailModule = new Map<Id, Id>();
                for(Trail_Module__c trailModule: moduleId.Trails_Modules__r){
                    trailByTrailModule.put(trailModule.Id, trailModule.Trail__c);
                    trailModuleId = trailModule.Id;
                }
                Map<Id, Set<Id>> trailIdByModuleProgressId = new Map<Id, Set<Id>>();
                Set<Id> trailId = new Set<Id>();
    
                for(Module_Progress__c modulePro: moduleId.Modules_Progress__r){
                    for(Trail_Module__c trailMod: moduleId.Trails_Modules__r){
                        if(trailByTrailModule.get(trailModuleId) != null){//map.get(key) != null
                                trailId.add(trailByTrailModule.get(trailMod.Id));
                        }
                    }
                    trailIdByModuleProgressId.put(modulePro.Id, trailId);
                }
            }

            Unit_Progress__c unitProgressToInsert = new Unit_Progress__c(Module_Progress__c = moduleProgressByUnit.get(unitId), User__c = userId, Unit__c = unitId, Points__c = unitQuery.Points__c,  Status__c = 'Draft');

            insert unitProgressToInsert;
        }
    }

    @AuraEnabled(cacheable=false)
    public static String metodoDos(Id unitId, String optionByQuestion){
        Id userId = UserInfo.getUserId();
        System.debug(unitId + ' ' + optionByQuestion);

        //TRAER QUESTION PROGRESS PARA VER SI EXISTE. SI EXISTE NO CREAR UNO NUEVO Y ACTUALIZAR LOS DATOS
        //CASO CONTRARIO CREAR QUESTION PROGRESS

        Unit_Progress__c insertedUnitProgress = [SELECT Id, Status__c, Counter__c, Points__c, Unit__r.Points__c, (SELECT Question__c, Option__c FROM Questions_Progress__r) FROM Unit_Progress__c WHERE Unit__c = :unitId AND User__c = :userId];

        Map<Id, Id> optionsByQuestion = (Map<Id, Id>)JSON.deserializeStrict( optionByQuestion, Map<Id, Id>.class);

        System.debug(insertedUnitProgress.Questions_Progress__r.size());
        //insertedUnitProgress.Questions_Progress__r.size() <= 0 || insertedUnitProgress.Questions_Progress__r == null
        //insertedUnitProgress.Questions_Progress__r.size() > 0 || insertedUnitProgress.Questions_Progress__r != null
        
        if(insertedUnitProgress.Questions_Progress__r.size() <= 0 || insertedUnitProgress.Questions_Progress__r == null){
            insertedUnitProgress.Status__c = 'Answered';
    
            List<Question_Progress__c> questionProgressToInsert = new List<Question_Progress__c>();
            
            Set<Id> questionIds = optionsByQuestion.keySet();
            for (Id question : questionIds) {
                Question_Progress__c questionProgress = new Question_Progress__c(Unit_Progress__c = insertedUnitProgress.Id, Question__c = question, Option__c = optionsByquestion.get(question));
                questionProgressToInsert.add(questionProgress);
            }
    
            insert questionProgressToInsert;
    
            update insertedUnitProgress;

        } else if(insertedUnitProgress.Questions_Progress__r.size() > 0 || insertedUnitProgress.Questions_Progress__r != null){
            insertedUnitProgress.Status__c = 'Answered';

            List<Question_Progress__c> questionProgressToUpdate= new List<Question_Progress__c>();
            for(Question_Progress__c questionProgress: insertedUnitProgress.Questions_Progress__r){
                questionProgressToUpdate.add(questionProgress);
            }
            
            for(Question_Progress__c questionPro: questionProgressToUpdate){
                System.debug(questionPro);
                if(optionsByQuestion.containsKey(questionPro.Question__c)){
                    System.debug(optionsByQuestion.containsKey(questionPro.Question__c));
                    System.debug(optionsByQuestion.get(questionPro.Question__c));
                    questionPro.Option__c = optionsByQuestion.get(questionPro.Question__c);
                }
            }

            update questionProgressToUpdate;

            update insertedUnitProgress;
        }

        Unit_Progress__c refreshedUnit = [SELECT Id, Status__c FROM Unit_Progress__c WHERE User__c = :userId AND Unit__c = :unitId AND Id = :insertedUnitProgress.Id];
        
        return refreshedUnit.Status__c;
    }  
    
    public class TrailWrapper{
        @AuraEnabled
        public Trail__c trail; 
        //Registro de Trail solicitado
        @AuraEnabled
        public Integer progressTrail; 
        //Porcentaje de progreso del Alumno en el Trail
        //Módulos con Unidades relacionadas
        @AuraEnabled
        public List<Module__c> modules = new List<Module__c>();
        @AuraEnabled
        public List<Module_Progress__c> passedModuleIds = new List<Module_Progress__c>();
        //Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
        @AuraEnabled
        public List<Id> passedUnitIds = new List<Id>();
        //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
        
        public TrailWrapper(Trail__c trail, List<Module__c> modules, List<Module_Progress__c> passedModuleIds, List<Id> passedUnitIds){
            this.trail = trail;
            this.modules = modules;
            this.progressTrail = (passedModuleIds.size()*100) / modules.size();
            this.passedModuleIds = passedModuleIds;
            this.passedUnitIds = passedUnitIds;
        }
    }

    //↓ Esto es lo que llamo desde el front y hace referencia a la clase TrailWrapper y su constructor para poder crear la instancia con el trailId pasado como parametro
    @AuraEnabled(cacheable=true)
    public static TrailWrapper getTrailWrapper(Id trailId){
        Id userId = UserInfo.getUserId();

        TrailWrapper trail = new TrailWrapper(([SELECT Name, Description__c, Time__c, Points__c FROM Trail__c WHERE Id = :trailId]), getModule(trailId), getCompletedModules(trailId), getUnitsWithProgress(trailId));
        return trail;
    }
    
    //Lineas 120 y 132 son lo mismo
    public static Set<Id> getTrailModule(Id trailId){

        List<Trail_Module__c> trailModulesFromTrail = [SELECT Id FROM Trail_Module__c WHERE Trail__c = :trailId];

        Set<Id> trailModuleIds = new Set<Id>();

        for(Trail_Module__c trailModule: trailModulesFromTrail){
            trailModuleIds.add(trailModule.Id);
        }
        return trailModuleIds;
    }

    public static List<Module__c> getModule(Id trailId){
        Id userId = UserInfo.getUserId();
        Set<Id> trailModuleIds = getTrailModule(trailId);

        List<Module__c> modules = [SELECT Name, Time__c, Points__c, Description__c, Image__c,Url__c,(SELECT Name, Time__c, Points__c,Url__c FROM Units__r), (SELECT Id, Module__c FROM Modules_Progress__r WHERE Status__c = 'Completed' AND User__c = :userId) FROM Module__c WHERE Id IN (SELECT Module__c FROM Trail_Module__c WHERE Id IN :trailModuleIds)];

        return modules;
    }

    public static List<Id> getUnitsWithProgress(Id trailId){
        Id userId = UserInfo.getUserId();
        List<Module__c> modules = getModule(trailId);

        Set<Id> unitIds = new Set<Id>();
        for(Module__c module: modules){
            for(Unit__c unit: module.Units__r){
                unitIds.add(unit.Id);
            }
        }

        List<Unit__c> unitsWithCompletedStatus = [SELECT Id FROM Unit__c WHERE Id IN :unitIds AND Id IN(SELECT Unit__c FROM Unit_Progress__C WHERE Status__c = 'Success' AND User__c = :userId)];

        List<Id> completedUnitIds = new List<Id>();
        for(Unit__c unit: unitsWithCompletedStatus){
            completedUnitIds.add(unit.Id);
        }

        return completedUnitIds;
    }

    public static List<Module_Progress__c> getCompletedModules(Id trailId){
        List<Module__c> modules = getModule(trailId);

        List<Module_Progress__c> moduleProgress = new List<Module_Progress__c>();
        for(Module__c module: modules){
            for(Module_Progress__c modulePro: module.Modules_Progress__r){
                moduleProgress.add(modulePro);
            }
        }
        return moduleProgress;
    }
    
    public class UnitWrapper{
        @AuraEnabled
        public Unit__c thisUnit;
        //Registro de Unidad solicitada
        @AuraEnabled
        public List<Question__c> thisQuestions = new List<Question__c>();  
        //Listado de Preguntas con Opciones relacionadas

        public UnitWrapper(Unit__c thisUnit, List<Question__c> thisQuestions){
            this.thisUnit = thisUnit;
            this.thisQuestions = thisQuestions;
        }
    }

    @AuraEnabled(cacheable=true)
    public static UnitWrapper getUnitWrapper(Id unitId){

        // TrailWrapper trail = new TrailWrapper(([SELECT Name, Description__c, Time__c, Points__c FROM Trail__c WHERE Id = :trailId]), getModule(trailId), getCompletedModules(trailId), getUnitsWithProgress(trailId));
        // return trail;

        UnitWrapper unitWrapper = new UnitWrapper(([SELECT Content__c, Points__c, Time__c,Url__c, Name FROM Unit__c WHERE Id = :unitId]), getQuestionsFromUnit(unitId));
        return unitWrapper;
    }

    // @AuraEnabled(cacheable=true)
    // public static Unit__c getUnit(Id unitId){
    //     Unit__c unit = [SELECT Name, Content__c, Points__c, Time__c FROM Unit__c WHERE Id = :unitId];
    //     return unit;
    // }

    public static List<Question__c> getQuestionsFromUnit(Id unitId){
        List<Question__c> questions = [SELECT Content__c, (SELECT Id, Content__c, IsCorrect__c FROM Options__r), (SELECT IsCompleted__c, Option__c, Question__c FROM Questions_Progress__r) FROM Question__c WHERE Unit__c =: unitId];

        return questions;
    }
}




