// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if canImport(Combine) && swift(>=5.0) && canImport(FirebaseAuth)

  import Combine
  import FirebaseAuth

  @available(swift 5.0)
  @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
  public typealias AuthStateDidChangePublisher = AnyPublisher<(Auth, User?), Never>

  @available(swift 5.0)
  @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
  extension Auth {
    // MARK: - Authentication State Management

    /// Registers a publisher that publishes authentication state changes.
    ///
    /// The publisher emits values when:
    ///
    /// - It is registered,
    /// - A user with a different UID from the current user has signed in, or
    /// - The current user has signed out.
    ///
    /// - Returns: A publisher emitting (`Auth`, User`) tuples.
    public func authStateDidChangePublisher() -> AuthStateDidChangePublisher {
      let subject = PassthroughSubject<(Auth, User?), Never>()
      let handle = addStateDidChangeListener { auth, user in
        subject.send((auth, user))
      }
      return subject
        .handleEvents(receiveCancel: {
          self.removeStateDidChangeListener(handle)
        })
        .eraseToAnyPublisher()
    }

    /// Registers a publisher that publishes ID token state changes.
    ///
    /// The publisher emits values when:
    ///
    /// - It is registered,
    /// - A user with a different UID from the current user has signed in,
    /// - The ID token of the current user has been refreshed, or
    /// - The current user has signed out.
    ///
    /// - Returns: A publisher emitting (`Auth`, User`) tuples.
    public func idTokenDidChangePublisher() -> AnyPublisher<(Auth, User?), Never> {
      let subject = PassthroughSubject<(Auth, User?), Never>()
      let handle = addIDTokenDidChangeListener { auth, user in
        subject.send((auth, user))
      }
      return subject
        .handleEvents(receiveCancel: {
          self.removeIDTokenDidChangeListener(handle)
        })
        .eraseToAnyPublisher()
    }

    // MARK: - Anonymous Authentication

    /// Asynchronously creates and becomes an anonymous user.
    /// - Returns: A publisher that emits the result of the sign in flow.
    /// - Remark: If there is already an anonymous user signed in, that user will be returned instead.
    ///   If there is any other existing user signed in, that user will be signed out.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeOperationNotAllowed` - Indicates that anonymous accounts are
    ///   not enabled. Enable them in the Auth section of the Firebase console.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    @discardableResult
    public func signInAnonymously() -> Future<AuthDataResult, Error> {
      Future<AuthDataResult, Error> { promise in
        self.signInAnonymously { authDataResult, error in
          if let error = error {
            promise(.failure(error))
          } else if let authDataResult = authDataResult {
            promise(.success(authDataResult))
          }
        }
      }
    }

    // MARK: - Email/Password Authentication

    /// Creates and, on success, signs in a user with the given email address and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's desired password.
    /// - Returns: A publisher that emits the result of the sign in flow.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeInvalidEmail` - Indicates the email address is malformed.
    /// - `AuthErrorCodeEmailAlreadyInUse` - Indicates the email used to attempt sign up
    ///   already exists. Call fetchProvidersForEmail to check which sign-in mechanisms the user
    ///   used, and prompt the user to sign in with one of those.
    /// - `AuthErrorCodeOperationNotAllowed` - Indicates that email and password accounts
    ///   are not enabled. Enable them in the Auth section of the Firebase console.
    /// - `AuthErrorCodeWeakPassword` - Indicates an attempt to set a password that is
    ///   considered too weak. The NSLocalizedFailureReasonErrorKey field in the NSError.userInfo
    ///   dictionary object will contain more detailed explanation that can be shown to the user.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    @discardableResult
    public func createUser(withEmail email: String,
                           password: String) -> Future<AuthDataResult, Error> {
      Future<AuthDataResult, Error> { [weak self] promise in
        self?.createUser(withEmail: email, password: password) { authDataResult, error in
          if let error = error {
            promise(.failure(error))
          } else if let authDataResult = authDataResult {
            promise(.success(authDataResult))
          }
        }
      }
    }

    /// Signs in using an email address and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's desired password.
    /// - Returns: A publisher that emits the result of the sign in flow.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeOperationNotAllowed` - Indicates that email and password
    ///   accounts are not enabled. Enable them in the Auth section of the
    ///   Firebase console.
    /// - `AuthErrorCodeUserDisabled` - Indicates the user's account is disabled.
    /// - `AuthErrorCodeWrongPassword` - Indicates the user attempted
    ///   sign in with an incorrect password.
    /// - `AuthErrorCodeInvalidEmail` - Indicates the email address is malformed.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    @discardableResult
    public func signIn(withEmail email: String,
                       password: String) -> Future<AuthDataResult, Error> {
      Future<AuthDataResult, Error> { [weak self] promise in
        self?.signIn(withEmail: email, password: password) { authDataResult, error in
          if let error = error {
            promise(.failure(error))
          } else if let authDataResult = authDataResult {
            promise(.success(authDataResult))
          }
        }
      }
    }

    // MARK: - Email/Link Authentication

    /// Signs in using an email address and email sign-in link.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - link: The email sign-in link.
    /// - Returns: A publisher that emits the result of the sign in flow.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeOperationNotAllowed` - Indicates that email and password
    ///   accounts are not enabled. Enable them in the Auth section of the
    ///   Firebase console.
    /// - `AuthErrorCodeUserDisabled` - Indicates the user's account is disabled.
    /// - `AuthErrorCodeInvalidEmail` - Indicates the email address is malformed.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    @discardableResult
    public func signIn(withEmail email: String,
                       link: String) -> Future<AuthDataResult, Error> {
      Future<AuthDataResult, Error> { [weak self] promise in
        self?.signIn(withEmail: email, link: link) { authDataResult, error in
          if let error = error {
            promise(.failure(error))
          } else if let authDataResult = authDataResult {
            promise(.success(authDataResult))
          }
        }
      }
    }

    /// Sends a sign in with email link to provided email address.
    /// - Parameters:
    ///   - email: The email address of the user.
    ///   - actionCodeSettings: An `ActionCodeSettings` object containing settings related to
    ///     handling action codes.
    /// - Returns: A publisher that emits whether the call was successful or not.
    @discardableResult
    public func sendSignInLink(toEmail email: String,
                               actionCodeSettings: ActionCodeSettings) -> Future<Void, Error> {
      Future<Void, Error> { [weak self] promise in
        self?.sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        }
      }
    }

    //  MARK: - Email-based Authentication Helpers

    /// Fetches the list of all sign-in methods previously used for the provided email address.
    /// - Parameter email: The email address for which to obtain a list of sign-in methods.
    /// - Returns: A publisher that emits a list of sign-in methods for the specified email
    ///   address, or an error if one occurred.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeInvalidEmail` - Indicates the email address is malformed.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    public func fetchSignInMethods(forEmail email: String) -> Future<[String], Error> {
      Future<[String], Error> { [weak self] promise in
        self?.fetchSignInMethods(forEmail: email) { signInMethods, error in
          if let error = error {
            promise(.failure(error))
          } else if let signInMethods = signInMethods {
            promise(.success(signInMethods))
          }
        }
      }
    }

    // MARK: - Password Reset

    /// Resets the password given a code sent to the user outside of the app and a new password for the user.
    /// - Parameters:
    ///   - code: Out-of-band code given to the user outside of the app.
    ///   - newPassword: The new password.
    /// - Returns: A publisher that emits whether the call was successful or not.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeWeakPassword` - Indicates an attempt to set a password that is considered too weak.
    /// - `AuthErrorCodeOperationNotAllowed` - Indicates the administrator disabled sign in with the specified identity provider.
    /// - `AuthErrorCodeExpiredActionCode` - Indicates the OOB code is expired.
    /// - `AuthErrorCodeInvalidActionCode` - Indicates the OOB code is invalid.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    public func confirmPasswordReset(withCode code: String,
                                     newPassword: String) -> Future<Void, Error> {
      Future<Void, Error> { [weak self] promise in
        self?.confirmPasswordReset(withCode: code, newPassword: newPassword) { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        }
      }
    }

    /// Checks the validity of a verify password reset code.
    /// - Parameter code: The password reset code to be verified.
    /// - Returns: A publisher that emits an error if the code could not be verified. If the code could be
    ///   verified, the publisher will emit the email address of the account the code was issued for.
    public func verifyPasswordResetCode(_ code: String) -> Future<String, Error> {
      Future<String, Error> { [weak self] promise in
        self?.verifyPasswordResetCode(code) { email, error in
          if let error = error {
            promise(.failure(error))
          } else if let email = email {
            promise(.success(email))
          }
        }
      }
    }

    /// Checks the validity of an out of band code.
    /// - Parameter code: The out of band code to check validity.
    /// - Returns: A publisher that emits an error if the code could not be verified. If the code could be
    ///   verified, the publisher will emit the email address of the account the code was issued for.
    public func checkActionCode(code: String) -> Future<ActionCodeInfo, Error> {
      Future<ActionCodeInfo, Error> { [weak self] promise in
        self?.checkActionCode(code) { actionCodeInfo, error in
          if let error = error {
            promise(.failure(error))
          } else if let actionCodeInfo = actionCodeInfo {
            promise(.success(actionCodeInfo))
          }
        }
      }
    }

    /// Applies out of band code.
    /// - Parameter code: The out of band code to be applied.
    /// - Returns: A publisher that emits an error if the code could not be applied.
    /// - Remark: This method will not work for out of band codes which require an additional parameter,
    ///   such as password reset code.
    public func applyActionCode(code: String) -> Future<Void, Error> {
      Future<Void, Error> { [weak self] promise in
        self?.applyActionCode(code) { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        }
      }
    }

    /// Initiates a password reset for the given email address.
    /// - Parameter email: The email address of the user.
    /// - Returns: A publisher that emits whether the call was successful or not.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeInvalidRecipientEmail` - Indicates an invalid recipient email was sent in the request.
    /// - `AuthErrorCodeInvalidSender` - Indicates an invalid sender email is set in the console for this action.
    /// - `AuthErrorCodeInvalidMessagePayload` - Indicates an invalid email template for sending update email.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    public func sendPasswordReset(withEmail email: String) -> Future<Void, Error> {
      Future<Void, Error> { [weak self] promise in
        self?.sendPasswordReset(withEmail: email) { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        }
      }
    }

    /// Initiates a password reset for the given email address and `ActionCodeSettings`.
    /// - Parameter email: The email address of the user.
    /// - Parameter actionCodeSettings: An `ActionCodeSettings` object containing settings related t handling action codes.
    /// - Returns: A publisher that emits whether the call was successful or not.
    /// - Remark: Possible error codes:
    /// - `AuthErrorCodeInvalidRecipientEmail` - Indicates an invalid recipient email was sent in the request.
    /// - `FIRAuthErrorCodeInvalidSender` - Indicates an invalid sender email is set in the console for this action.
    /// - `AuthErrorCodeInvalidMessagePayload` - Indicates an invalid email template for sending update email.
    /// - `AuthErrorCodeMissingIosBundleID` - Indicates that the iOS bundle ID is missing when `handleCodeInApp` is set to YES.
    /// - `AuthErrorCodeMissingAndroidPackageName` - Indicates that the android package name is missing when the `androidInstallApp` flag is set to true.
    /// - `AuthErrorCodeUnauthorizedDomain` - Indicates that the domain specified in the continue URL is not whitelisted in the Firebase console.
    /// - `AuthErrorCodeInvalidContinueURI` - Indicates that the domain specified in the continue URI is not valid.
    /// - Remark: See `AuthErrors` for a list of error codes that are common to all API methods
    public func sendPasswordReset(withEmail email: String,
                                  actionCodeSettings: ActionCodeSettings) -> Future<Void, Error> {
      Future<Void, Error> { [weak self] promise in
        self?.sendPasswordReset(withEmail: email, actionCodeSettings: actionCodeSettings) { error in
          if let error = error {
            promise(.failure(error))
          } else {
            promise(.success(()))
          }
        }
      }
    }
  }
#endif