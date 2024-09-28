import { Project, Module, Task } from '../Models/model.js';  // Vérifiez le chemin d'importation
import axios from 'axios';

export async function createProject(req, res) {
    try {
        const { modules, name, keywords, teamLeader,members, description, startDate, endDate } = req.body;

        // Validation du project_name
        if (!name || typeof name !== 'string') {
            return res.status(400).json({ message: 'Invalid project data: project_name must be a string' });
        }
        
        // Validation de la description
        if (!description || typeof description !== 'string') {
            return res.status(400).json({ message: 'Invalid project data: description is required and must be a string' });
        }

        // Validation des dates
        if (!startDate || !endDate) {
            return res.status(400).json({ message: 'Start date and end date are required' });
        }
        if (new Date(startDate) > new Date(endDate)) {
            return res.status(400).json({ message: 'Start date must be before end date' });
        }

        // Création du projet
        const newProject = new Project({
            name: name,
            description: description,
            startDate: startDate,
            endDate: endDate,
            keywords: keywords,
            teamLeader: teamLeader,
            members: members,
            isComplete: false
        });

        const savedProject = await newProject.save();

        // Processus pour les modules et tâches, si présents
        if (modules && Array.isArray(modules)) {
            for (const mod of modules) {
                const newModule = new Module({
                    module_name: mod.module_name,
                    teamM: mod.teamM,
                    projectID: savedProject._id
                });
                const savedModule = await newModule.save();

                // Création des tâches associées à ce module
                for (const task of mod.tasks) {
                    const newTask = new Task({
                        module_id: savedModule._id,
                        team: task.team,
                    
                        task_description: task.task_description,
                        projectID: savedProject._id
                    });
                    await newTask.save();
                }
            }
        }

        res.status(201).json({ message: 'Project created successfully', project: newProject });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Internal server error', error: error });
    }
}



export async function predictTaskDuration(projectId) {
    try {
        const response = await axios.get(`http://localhost:5000/predict_task_duration/${projectId}`);
        return response.data; // Retourne toute la réponse
    } catch (error) {
        // Affichage de plus de détails sur l'erreur
        console.error('Error fetching task durations:', error.response ? error.response.data : error.message);
        // Relance d'une nouvelle erreur pour signaler le problème
        throw new Error('Error fetching task durations from server');
    }
}


// Fonction pour obtenir tous les projets avec lemail

export const getProjectsByEmail = async (req, res) => {
    const { email } = req.body;

    try {
        // Recherche des projets où le champ 'members.email' contient l'email donné
        const projects = await Project.find({ members: email });  // Correction pour recherche dans un tableau d'objets

        if (projects.length === 0) {
            // Si aucun projet n'est trouvé, retournez un 404
            return res.status(404).json({ message: "Aucun projet trouvé pour cet email email email." });
        }

        // Création de structures de données temporaires pour stocker les informations enrichies
        const enrichedProjects = await Promise.all(projects.map(async project => {
            const modules = await Module.find({ projectID: project._id }).lean().exec();
            const enrichedModules = await Promise.all(modules.map(async module => {
                const tasks = await Task.find({ module_id: module._id }).lean().exec();
                return { ...module, tasks };
            }));
            return { ...project.toObject(), modules: enrichedModules };
        }));

        // Filtrer les projets complétés et non complétés
        const completedProjects = enrichedProjects.filter(project => project.isComplete);
        const incompleteProjects = enrichedProjects.filter(project => !project.isComplete);

        // Envoyer la réponse avec les projets complétés et non complétés
        res.status(200).json({ completedProjects, incompleteProjects });
    } catch (error) {
        console.error('Error fetching projects:', error);
        res.status(400).json({ message: error.message });
    }
};
