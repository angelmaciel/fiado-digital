import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { MetodoAuth, RolUsuario, type Usuario } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';

export interface PerfilGoogle {
  googleUid: string;
  email: string;
  nombre: string;
}

@Injectable()
export class UsuariosService {
  private readonly logger = new Logger(UsuariosService.name);

  constructor(private readonly prisma: PrismaService) {}

  async buscarPorId(id: string): Promise<Usuario> {
    const usuario = await this.prisma.usuario.findUnique({ where: { id } });
    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }
    return usuario;
  }

  async buscarPorIdONull(id: string): Promise<Usuario | null> {
    return this.prisma.usuario.findUnique({ where: { id } });
  }

  async buscarPorEmail(email: string): Promise<Usuario | null> {
    return this.prisma.usuario.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
  }

  async crearConEmailYPassword(datos: {
    nombre: string;
    email: string;
    passwordHash: string;
  }): Promise<Usuario> {
    return this.prisma.usuario.create({
      data: {
        nombre: datos.nombre,
        email: datos.email.trim().toLowerCase(),
        metodoAuth: MetodoAuth.EMAIL_PASSWORD,
        passwordHash: datos.passwordHash,
        emailVerificado: false,
        rol: RolUsuario.DUENO,
        despensaId: null,
      },
    });
  }

  async actualizarPerfil(id: string, nombre: string): Promise<Usuario> {
    return this.prisma.usuario.update({
      where: { id },
      data: { nombre: nombre.trim() },
    });
  }

  async marcarEmailVerificado(id: string): Promise<Usuario> {
    return this.prisma.usuario.update({
      where: { id },
      data: { emailVerificado: true },
    });
  }

  /**
   * Reintento de registro sobre una cuenta que nunca llegó a verificarse.
   * A diferencia de `cambiarPassword`, NO marca el correo como verificado:
   * todavía no probó nada.
   */
  async cambiarPasswordSinVerificar(id: string, passwordHash: string): Promise<Usuario> {
    return this.prisma.usuario.update({
      where: { id },
      data: { passwordHash },
    });
  }

  async cambiarPassword(id: string, passwordHash: string): Promise<Usuario> {
    return this.prisma.usuario.update({
      where: { id },
      // Restablecer la contraseña prueba que controla el correo, así que
      // también queda verificado.
      data: { passwordHash, emailVerificado: true },
    });
  }

  /**
   * Resuelve el usuario detrás de un login con Google (HU-01):
   *
   * 1. Si ya existe por `google_uid`, actualiza el nombre y lo devuelve.
   * 2. Si existe por email pero sin `google_uid`, vincula la cuenta. Google ya
   *    verificó el email (AuthService rechaza los no verificados), así que es
   *    seguro asociarlas en vez de crear un usuario duplicado.
   * 3. Si no existe, lo crea como DUENO y **sin despensa**: la crea después en
   *    el onboarding, porque en el login no conocemos el nombre comercial.
   */
  async buscarOCrearDesdeGoogle(perfil: PerfilGoogle): Promise<Usuario> {
    const email = perfil.email.trim().toLowerCase();

    const porGoogleUid = await this.prisma.usuario.findUnique({
      where: { googleUid: perfil.googleUid },
    });

    if (porGoogleUid) {
      if (porGoogleUid.nombre !== perfil.nombre || porGoogleUid.email !== email) {
        return this.prisma.usuario.update({
          where: { id: porGoogleUid.id },
          data: { nombre: perfil.nombre, email },
        });
      }
      return porGoogleUid;
    }

    const porEmail = await this.prisma.usuario.findUnique({ where: { email } });

    if (porEmail) {
      this.logger.log(`Vinculando cuenta de Google al usuario existente ${porEmail.id}`);
      return this.prisma.usuario.update({
        where: { id: porEmail.id },
        data: {
          googleUid: perfil.googleUid,
          nombre: porEmail.nombre || perfil.nombre,
          // Google ya comprobó que es dueño del correo: si se había registrado
          // con contraseña y nunca verificó, esto lo da por verificado.
          emailVerificado: true,
        },
      });
    }

    const nuevo = await this.prisma.usuario.create({
      data: {
        nombre: perfil.nombre,
        email,
        metodoAuth: MetodoAuth.GOOGLE,
        googleUid: perfil.googleUid,
        emailVerificado: true,
        rol: RolUsuario.DUENO,
        despensaId: null,
      },
    });

    this.logger.log(`Usuario creado desde Google: ${nuevo.id}`);
    return nuevo;
  }
}
