import { NivelEducativo } from "../entities/NivelEducativo";

export interface NivelesRepository {
  findAll(): Promise<NivelEducativo[]>;
}
