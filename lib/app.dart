import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/register_with_email_password.dart';
import 'features/auth/domain/usecases/send_password_reset_email.dart';
import 'features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/employee/data/datasources/country_remote_data_source.dart';
import 'features/employee/data/datasources/employee_local_data_source.dart';
import 'features/employee/data/datasources/employee_remote_data_source.dart';
import 'features/employee/data/repositories/country_repository_impl.dart';
import 'features/employee/data/repositories/employee_repository_impl.dart';
import 'features/employee/domain/repositories/country_repository.dart';
import 'features/employee/domain/repositories/employee_repository.dart';
import 'features/employee/domain/usecases/create_employee.dart';
import 'features/employee/domain/usecases/delete_employee.dart';
import 'features/employee/domain/usecases/get_countries.dart';
import 'features/employee/domain/usecases/get_employee_by_id.dart';
import 'features/employee/domain/usecases/get_employees.dart';
import 'features/employee/domain/usecases/update_employee.dart';
import 'features/employee/presentation/providers/country_provider.dart';
import 'features/employee/presentation/providers/employee_provider.dart';

class ExelyntApp extends StatelessWidget {
  const ExelyntApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),

        Provider<AuthRemoteDataSource>(create: (_) => FirebaseAuthRemoteDataSource()),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(context.read<AuthRemoteDataSource>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            final repository = context.read<AuthRepository>();
            return AuthProvider(
              authRepository: repository,
              signInWithEmailPassword: SignInWithEmailPassword(repository),
              registerWithEmailPassword: RegisterWithEmailPassword(repository),
              signInWithGoogle: SignInWithGoogle(repository),
              sendPasswordResetEmail: SendPasswordResetEmail(repository),
              signOut: SignOut(repository),
            );
          },
        ),

        Provider<ApiClient>(create: (_) => ApiClient()),

        Provider<EmployeeRemoteDataSource>(
          create: (context) => EmployeeApiDataSource(context.read<ApiClient>()),
        ),
        Provider<EmployeeLocalDataSource>(create: (_) => EmployeeSharedPrefsDataSource()),
        Provider<EmployeeRepository>(
          create: (context) => EmployeeRepositoryImpl(
            context.read<EmployeeRemoteDataSource>(),
            context.read<EmployeeLocalDataSource>(),
          ),
        ),
        ChangeNotifierProvider<EmployeeProvider>(
          create: (context) {
            final repository = context.read<EmployeeRepository>();
            return EmployeeProvider(
              repository: repository,
              getEmployees: GetEmployees(repository),
              getEmployeeById: GetEmployeeById(repository),
              createEmployee: CreateEmployee(repository),
              updateEmployee: UpdateEmployee(repository),
              deleteEmployee: DeleteEmployee(repository),
            );
          },
        ),

        Provider<CountryRemoteDataSource>(
          create: (context) => CountryApiDataSource(context.read<ApiClient>()),
        ),
        Provider<CountryRepository>(
          create: (context) => CountryRepositoryImpl(context.read<CountryRemoteDataSource>()),
        ),
        ChangeNotifierProvider<CountryProvider>(
          create: (context) =>
              CountryProvider(getCountries: GetCountries(context.read<CountryRepository>())),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Exelynt Learning',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
