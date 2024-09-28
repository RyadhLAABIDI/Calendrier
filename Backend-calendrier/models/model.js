// Importation de mongoose
import mongoose from 'mongoose';

// Schéma pour Project
const projectSchema = new mongoose.Schema({
    name: String,
    total_duration: { type: Number, required: false },
    startDate: Date,
    endDate: Date,
    description: String,
    keywords: [String],
    teamLeader: String,
    members: [String],
    isComplete: { type: Boolean, required: true, default: false },
    
});
const Project = mongoose.model('Project', projectSchema);

// Schéma pour Module
const moduleSchema = new mongoose.Schema({
    module_name: String,
    total_duration: { type: Number, required: false },
    module_start_date: { type: Date, required: false },
    module_end_date: { type: Date, required: false },
    teamM: [{ type: String }] ,
    projectID: { type: mongoose.Schema.Types.ObjectId, ref: 'Project' },
    
});
const Module = mongoose.model('Module', moduleSchema);

// Schéma pour Task
const taskSchema = new mongoose.Schema({
    module_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Module', required: true },
    task_description: { type: String, required: true },
    duration: { type: Number, required: false },
    start_date: { type: Date, required: false },
    end_date: { type: Date, required: false },
    team: [{ type: String }],
    completed: { type: Boolean, default: false },
    projectID: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true },
    
});
const Task = mongoose.model('Task', taskSchema);

// Exportation des modèles
export { Project, Module, Task };
