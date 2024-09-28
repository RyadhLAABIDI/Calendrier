import { Router } from 'express';
const router = Router();
import {  createProject, predictTaskDuration, getProjectsByEmail } from '../controllers/planningController.js';
import { Task, Project, Module } from '../models/models.js';


////// create Prjt
router.post('/create', createProject);

//  Get  by emaaiiillll
router.post('/getbyemail', getProjectsByEmail);

//// prediction des taches 

router.post('/predict_task_duration/:projectId', async (req, res) => {
    try {
        const projectId = req.params.projectId;
        const { email } = req.body;  // Récupération de l'email depuis le corps de la requête
        
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }
        // Recherche du projet spécifique avec l'ID et vérification si l'email est celui du team leader
        const project = await Project.findOne({ _id: projectId, teamLeader: email });

        if (!project) {
            // Si le projet n'est pas trouvé ou si l'email n'est pas celui du team leader
            return res.status(403).json({ message: "Unauthorized: Only the team leader can perform this operation." });
        }

        const predictionResponse = await predictTaskDuration(projectId);

        if (predictionResponse.modules) {
            const modules = predictionResponse.modules;

            // Mise à jour des modules
            for (const module of modules) {
                const tasks = module.tasks;

                // Mise à jour des tâches pour chaque module
                for (const task of tasks) {
                    const taskId = task.id;
                    const duration = task.duration;
                    const startDate = task.start_date;
                    const endDate = task.end_date;

                    // Mise à jour de la tâche dans la base de données
                    await Task.findByIdAndUpdate(taskId, { duration, start_date: startDate, end_date: endDate });
                    console.log(`Tâche mise à jour - ID: ${taskId}, Durée: ${duration}, Date de début: ${startDate}, Date de fin: ${endDate}`);
                }

                // Mise à jour du module dans la base de données
                await Module.findByIdAndUpdate(module.id, {
                    total_duration: module.total_duration,
                    module_start_date: module.module_start_date,
                    module_end_date: module.module_end_date
                });
                console.log(`Module mis à jour - ID: ${module.id}, Durée totale: ${module.total_duration}, Date de début: ${module.module_start_date}, Date de fin: ${module.module_end_date}`);
            }

            // Mise à jour du projet dans la base de données
            await Project.findByIdAndUpdate(projectId, {
                total_duration: predictionResponse.project_info.total_duration,
                startDate: predictionResponse.project_info.startDate,
                endDate: predictionResponse.project_info.endDate,
                isComplete: true
            });

            console.log(`Projet mis à jour - ID: ${projectId}, Durée totale: ${predictionResponse.project_info.total_duration}, Date de début: ${predictionResponse.project_info.startDate}, Date de fin: ${predictionResponse.project_info.endDate}`);
        }

        res.status(200).json(predictionResponse);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Internal server error' });
    }
});
export default router;