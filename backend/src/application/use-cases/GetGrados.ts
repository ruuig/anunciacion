import { GradosRepository } from "../../domain/repositories/GradosRepository";

export class GetGrados {
  constructor(private readonly repo: GradosRepository) {}

  async execute() {
    return this.repo.findAll();
  }
}
