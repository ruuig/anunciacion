import { UserRepository } from "../../domain/repositories/UserRepository";
import { User } from "../../domain/entities/User";

export class AuthenticateUser {
  constructor(private readonly userRepo: UserRepository) {}

  async execute(input: { username: string; password: string }): Promise<User> {
    const user = await this.userRepo.findByUsername(input.username);
    if (!user) {
      throw new Error("INVALID_CREDENTIALS");
    }

    if (user.password !== input.password) {
      throw new Error("INVALID_CREDENTIALS");
    }

    await this.userRepo.updateLastAccess(user.id);

    return user;
  }
}
