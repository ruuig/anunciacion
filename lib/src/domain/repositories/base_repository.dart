// Interfaz base para todos los repositorios
abstract class BaseRepository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<T> update(T entity);
  Future<void> delete(ID id);
  Future<bool> existsById(ID id);
}

// Clase base abstracta que implementa BaseRepository
abstract class BaseRepositoryImpl<T, ID> implements BaseRepository<T, ID> {
  // Implementación por defecto de existsById
  @override
  Future<bool> existsById(ID id) async {
    final entity = await findById(id);
    return entity != null;
  }
}
