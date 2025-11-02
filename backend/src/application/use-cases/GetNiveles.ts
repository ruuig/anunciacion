import { NivelesRepository } from "../../domain/repositories/NivelesRepository";

export class GetNiveles {
  constructor(private readonly repo: NivelesRepository) {}

  async execute() {
    return this.repo.findAll();
  }
}
