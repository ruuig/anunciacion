import { Request, Response } from "express";
import { PostgresUserRepository } from "../../../../infrastructure/repositories/PostgresUserRepository";

const userRepository = new PostgresUserRepository();

export async function getAllUsers(req: Request, res: Response) {
  try {
    const users = await userRepository.findAll();
    
    // No enviar passwords en la respuesta
    const usersWithoutPassword = users.map(user => {
      const { password, ...userWithoutPassword } = user;
      return userWithoutPassword;
    });
    
    res.json(usersWithoutPassword);
  } catch (error: any) {
    console.error("Error getting users:", error);
    res.status(500).json({ 
      ok: false, 
      message: "Error al obtener usuarios",
      error: error.message 
    });
  }
}

export async function getUserById(req: Request, res: Response) {
  try {
    const id = parseInt(req.params.id);
    const user = await userRepository.findById(id);
    
    if (!user) {
      return res.status(404).json({ 
        ok: false, 
        message: "Usuario no encontrado" 
      });
    }
    
    // No enviar password en la respuesta
    const { password, ...userWithoutPassword } = user;
    res.json(userWithoutPassword);
  } catch (error: any) {
    console.error("Error getting user:", error);
    res.status(500).json({ 
      ok: false, 
      message: "Error al obtener usuario",
      error: error.message 
    });
  }
}

export async function createUser(req: Request, res: Response) {
  try {
    const { name, username, password, phone, roleId, status, avatarUrl } = req.body;
    
    // Validaciones básicas
    if (!name || !username || !password || !roleId) {
      return res.status(400).json({ 
        ok: false, 
        message: "Faltan campos requeridos: name, username, password, roleId" 
      });
    }
    
    // Verificar si el username ya existe
    const existingUser = await userRepository.findByUsername(username);
    if (existingUser) {
      return res.status(409).json({ 
        ok: false, 
        message: "El nombre de usuario ya existe" 
      });
    }
    
    const newUser = await userRepository.create({
      name,
      username,
      password,
      phone,
      roleId,
      status: status || 'activo',
      avatarUrl
    });
    
    // No enviar password en la respuesta
    const { password: _, ...userWithoutPassword } = newUser;
    res.status(201).json(userWithoutPassword);
  } catch (error: any) {
    console.error("Error creating user:", error);
    res.status(500).json({ 
      ok: false, 
      message: "Error al crear usuario",
      error: error.message 
    });
  }
}

export async function updateUser(req: Request, res: Response) {
  try {
    const id = parseInt(req.params.id);
    const updates = req.body;
    
    // Verificar que el usuario existe
    const existingUser = await userRepository.findById(id);
    if (!existingUser) {
      return res.status(404).json({ 
        ok: false, 
        message: "Usuario no encontrado" 
      });
    }
    
    // Si se está actualizando el username, verificar que no exista
    if (updates.username && updates.username !== existingUser.username) {
      const userWithSameUsername = await userRepository.findByUsername(updates.username);
      if (userWithSameUsername) {
        return res.status(409).json({ 
          ok: false, 
          message: "El nombre de usuario ya existe" 
        });
      }
    }
    
    const updatedUser = await userRepository.update(id, updates);
    
    // No enviar password en la respuesta
    const { password, ...userWithoutPassword } = updatedUser;
    res.json(userWithoutPassword);
  } catch (error: any) {
    console.error("Error updating user:", error);
    res.status(500).json({ 
      ok: false, 
      message: "Error al actualizar usuario",
      error: error.message 
    });
  }
}

export async function deleteUser(req: Request, res: Response) {
  try {
    const id = parseInt(req.params.id);
    
    // Verificar que el usuario existe
    const existingUser = await userRepository.findById(id);
    if (!existingUser) {
      return res.status(404).json({ 
        ok: false, 
        message: "Usuario no encontrado" 
      });
    }
    
    await userRepository.delete(id);
    res.json({ 
      ok: true, 
      message: "Usuario eliminado exitosamente" 
    });
  } catch (error: any) {
    console.error("Error deleting user:", error);
    res.status(500).json({ 
      ok: false, 
      message: "Error al eliminar usuario",
      error: error.message 
    });
  }
}
